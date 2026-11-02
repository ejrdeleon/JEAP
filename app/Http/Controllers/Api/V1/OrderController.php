<?php

namespace App\Http\Controllers\Api\V1;

use App\Commerce\CommissionService;
use App\Commerce\InventoryPolicy;
use App\Commerce\ShipmentWorkflow;
use App\Commerce\VoucherService;
use App\Notifications\OrderPlacedNotification;
use App\Enums\OrderStatus;
use App\Enums\PaymentStatus;
use App\Enums\ShipmentStatus;
use App\Http\Controllers\Controller;
use App\Models\Cart;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\OrderStatusHistory;
use App\Models\Parcel;
use App\Models\Payment;
use App\Models\PickupAssignment;
use App\Models\ProductVariant;
use App\Models\Review;
use App\Payments\PaymentGateway;
use App\Services\ShipmentService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\ConflictHttpException;

class OrderController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = Order::query()->with(['items', 'statusHistories.actor', 'parcel.deliveryAssignment.courier', 'shipment'])->latest('placed_at');

        $user = $request->user();

        if ($user->hasRole('admin')) {
            // Admins can view all orders across all accounts.
        } elseif ($user->hasRole('seller')) {
            $query->where('seller_id', $user->id);
        } else {
            $query->where('buyer_id', $user->id);
        }

        if ($request->filled('status')) {
            $query->where('status', strtoupper($request->status));
        }

        if ($request->filled('account_id')) {
            $query->where(function ($q) use ($request) {
                $q->where('buyer_id', $request->account_id)
                    ->orWhere('seller_id', $request->account_id);
            });
        }

        return response()->json(['orders' => $query->get()->map(fn ($o) => $this->orderPayload($o))]);
    }

    public function show(Request $request, string $orderNumber): JsonResponse
    {
        $query = Order::query()->where('order_number', $orderNumber)->with(['items', 'statusHistories.actor', 'parcel.deliveryAssignment.courier', 'shipment']);

        $user = $request->user();

        if ($user->hasRole('admin')) {
            // Admins can view any order by number.
        } elseif ($user->hasRole('seller')) {
            $query->where('seller_id', $user->id);
        } else {
            $query->where('buyer_id', $user->id);
        }

        $order = $query->firstOrFail();

        return response()->json(['order' => $this->orderPayload($order)]);
    }

    public function checkout(Request $request): JsonResponse
    {
        $data = $request->validate([
            'address_id' => ['required', 'integer'],
            'payment_method' => ['required', 'in:cod'],
            'voucher_code' => ['nullable', 'string'],
            'notes' => ['nullable', 'string', 'max:500'],
        ]);

        $address = $request->user()->addresses()->findOrFail($data['address_id']);

        $orders = DB::transaction(function () use ($address, $data, $request) {
            $cart = Cart::query()->where('user_id', $request->user()->id)->lockForUpdate()->first();
            $items = $cart?->items()->lockForUpdate()->get() ?? collect();
            if ($items->isEmpty()) {
                return null;
            }

            $grouped = $items->groupBy('seller_id');
            $orders = [];
            $groupId = Str::uuid()->toString();
            $voucherService = app(VoucherService::class);
            $voucherRedeemed = false;

            foreach ($grouped as $sellerId => $sellerItems) {
                foreach ($sellerItems as $item) {
                    $variant = ProductVariant::query()->whereKey($item->product_variant_id)
                        ->lockForUpdate()->with('product')->first();
                    if (! $variant || ! $variant->is_active || $variant->product?->status !== 'active') {
                        throw ValidationException::withMessages([
                            'cart' => 'A product in your cart is no longer available.',
                        ]);
                    }
                    if (! InventoryPolicy::isSellable($variant) || $item->quantity > InventoryPolicy::maxQtyPerProduct() || $variant->stock < $item->quantity) {
                        throw ValidationException::withMessages([
                            'cart' => "{$variant->product->name} cannot be ordered. Stock must be at least ".InventoryPolicy::minSellableStock().' and quantity cannot exceed '.InventoryPolicy::maxQtyPerProduct().'.',
                        ]);
                    }
                    $stock = InventoryPolicy::takeForOrder($variant, $item->quantity);
                    $item->unit_price = $variant->price;
                    $item->setRelation('variant', $variant);
                    $item->stock_before = $stock['stock_before'];
                    $item->stock_after = $stock['stock_after'];
                }

                $subtotal = $sellerItems->sum(fn ($i) => $i->unit_price * $i->quantity);
                $fee = InventoryPolicy::shippingFee();
                $discount = 0.00;
                $voucher = null;
                if (! $voucherRedeemed && ! empty($data['voucher_code'])) {
                    $voucher = $voucherService->findUsable($data['voucher_code'], $request->user(), (int) $sellerId, $subtotal);
                    $discount = $voucher?->computeDiscount($subtotal) ?? 0;
                }

                $order = Order::create([
                    'checkout_group_id' => $groupId,
                    'order_number' => 'JEAP-'.strtoupper(Str::random(8)),
                    'buyer_id' => $request->user()->id,
                    'seller_id' => $sellerId,
                    'status' => OrderStatus::Placed,
                    'subtotal' => $subtotal,
                    'shipping_fee' => $fee,
                    'discount' => $discount,
                    'total' => $subtotal - $discount + $fee,
                    'shipping_address_id' => $address->id,
                    'shipping_address_snapshot' => $address->toArray(),
                    'notes' => $data['notes'] ?? null,
                    'placed_at' => now(),
                ]);

                app(CommissionService::class)->record($order);
                if ($voucher && $discount > 0) {
                    $voucherService->redeem($voucher, $order, $request->user(), $discount);
                    $voucherRedeemed = true;
                }
                if ($order->seller?->wantsNotification('order_updates')) {
                    $order->seller->notify(new OrderPlacedNotification($order));
                }

                foreach ($sellerItems as $item) {
                    OrderItem::create([
                        'order_id' => $order->id,
                        'product_id' => $item->variant->product_id,
                        'product_variant_id' => $item->product_variant_id,
                        'name' => $item->variant->product->name,
                        'sku' => $item->variant->sku,
                        'quantity' => $item->quantity,
                        'stock_before' => $item->stock_before,
                        'stock_after' => $item->stock_after,
                        'unit_price' => $item->unit_price,
                        'subtotal' => $item->unit_price * $item->quantity,
                    ]);
                }

                OrderStatusHistory::create([
                    'order_id' => $order->id,
                    'to_status' => OrderStatus::Placed->value,
                    'created_at' => now(),
                ]);
                app(ShipmentService::class)->initializeShipment($order);

                $intent = app(PaymentGateway::class)->initiate($order);
                Payment::create([
                    'checkout_group_id' => $groupId,
                    'order_id' => $order->id,
                    'gateway' => $intent->gateway,
                    'method' => 'cod',
                    'amount' => $order->total,
                    'status' => $intent->status,
                    'gateway_reference' => $intent->reference,
                    'payload' => $intent->payload,
                ]);

                $orders[] = $order->load('items');
            }

            $cart->items()->delete();

            return $orders;
        });

        if ($orders === null) {
            return response()->json(['message' => 'Your cart is empty.'], 422);
        }

        return response()->json([
            'message' => 'Order placed successfully.',
            'orders' => array_map(fn ($o) => $this->orderPayload($o), $orders),
        ], 201);
    }

    public function confirmReceived(Request $request, string $orderNumber, ShipmentWorkflow $workflow): JsonResponse
    {
        $confirmed = DB::transaction(function () use ($request, $orderNumber, $workflow): bool {
            $order = Order::query()->where('buyer_id', $request->user()->id)
                ->where('order_number', $orderNumber)->lockForUpdate()->firstOrFail();

            if ($order->status !== OrderStatus::Delivered) {
                return false;
            }

            $parcel = $order->parcel()->lockForUpdate()->firstOrFail();
            $workflow->transition($order, $parcel, OrderStatus::Completed, $request->user(), 'Buyer confirmed receipt of the order.');

            return true;
        });

        if (! $confirmed) {
            return response()->json(['message' => 'Order is not in delivered status.'], 422);
        }

        return response()->json(['message' => 'Order marked as completed.']);
    }

    public function rate(Request $request, string $orderNumber): JsonResponse
    {
        $data = $request->validate([
            'product_id' => ['required', 'integer'],
            'rating' => ['required', 'numeric', 'min:1', 'max:5'],
            'review' => ['nullable', 'string', 'max:1000'],
        ]);

        $order = Order::where('buyer_id', $request->user()->id)
            ->where('order_number', $orderNumber)
            ->where('status', OrderStatus::Completed)
            ->firstOrFail();

        $item = $order->items()->where('product_id', $data['product_id'])->firstOrFail();

        Review::updateOrCreate(
            [
                'order_id' => $order->id,
                'product_id' => $data['product_id'],
                'buyer_id' => $request->user()->id,
            ],
            [
                'seller_id' => $order->seller_id,
                'rating' => (int) $data['rating'],
                'comment' => $data['review'] ?? null,
            ]
        );

        return response()->json(['message' => 'Rating submitted.']);
    }

    public function cancel(Request $request, string $orderNumber): JsonResponse
    {
        $data = $request->validate([
            'reason' => ['required', 'string', 'min:10', 'max:300'],
        ]);

        try {
            DB::transaction(function () use ($request, $orderNumber, $data): void {
                $order = Order::query()
                    ->where('buyer_id', $request->user()->id)
                    ->where('order_number', $orderNumber)
                    ->lockForUpdate()
                    ->firstOrFail();

                if (! in_array($order->status, [OrderStatus::Placed, OrderStatus::Confirmed, OrderStatus::Preparing], true)) {
                    throw new ConflictHttpException('This order can no longer be cancelled online.');
                }

                $from = $order->status;
                foreach ($order->items as $item) {
                    ProductVariant::query()->whereKey($item->product_variant_id)->increment('stock', $item->quantity);
                }
                $order->payments()->where('status', PaymentStatus::Pending->value)->update(['status' => PaymentStatus::Cancelled->value]);
                $order->commission()->update(['status' => 'void']);
                $order->update([
                    'status' => OrderStatus::Cancelled,
                    'cancellation_reason' => trim($data['reason']),
                ]);
                OrderStatusHistory::query()->create([
                    'order_id' => $order->id,
                    'from_status' => $from,
                    'to_status' => OrderStatus::Cancelled,
                    'actor_id' => $request->user()->id,
                    'notes' => 'Buyer cancelled the order: '.trim($data['reason']),
                    'created_at' => now(),
                ]);
                app(ShipmentService::class)->recordOrderMilestone(
                    $order->fresh(),
                    $request->user(),
                    ShipmentStatus::Cancelled,
                    ShipmentStatus::Cancelled->defaultTitle(),
                    null,
                    'Buyer cancelled the order.',
                    ['skip_proof' => true],
                );
            });
        } catch (ConflictHttpException $exception) {
            return response()->json(['message' => $exception->getMessage()], 409);
        }

        return response()->json(['message' => 'Order cancelled.']);
    }

    public function sellerUpdateStatus(Request $request, string $orderNumber): JsonResponse
    {
        $transitions = [
            OrderStatus::Placed->value => [OrderStatus::Confirmed, OrderStatus::Cancelled],
            OrderStatus::Confirmed->value => [OrderStatus::Preparing, OrderStatus::Cancelled],
            OrderStatus::Preparing->value => [OrderStatus::ReadyForPickup],
        ];
        $data = $request->validate([
            'status' => ['required', Rule::in(array_map(
                fn (OrderStatus $status) => $status->value,
                [OrderStatus::Confirmed, OrderStatus::Preparing, OrderStatus::ReadyForPickup, OrderStatus::Cancelled]
            ))],
            'notes' => ['nullable', 'string', 'max:500'],
        ]);
        $next = OrderStatus::from($data['status']);

        try {
            $order = DB::transaction(function () use ($request, $orderNumber, $next, $transitions, $data): Order {
                $order = Order::query()
                    ->where('seller_id', $request->user()->id)
                    ->where('order_number', $orderNumber)
                    ->lockForUpdate()
                    ->firstOrFail();

                $current = $order->status;
                if (! in_array($next, $transitions[$current->value] ?? [], true)) {
                    throw new ConflictHttpException('This order status transition is not allowed.');
                }

                if ($next === OrderStatus::Cancelled) {
                    foreach ($order->items as $item) {
                        ProductVariant::query()->whereKey($item->product_variant_id)->increment('stock', $item->quantity);
                    }
                    $order->payments()->where('status', PaymentStatus::Pending->value)->update(['status' => PaymentStatus::Cancelled->value]);
                    $order->commission()->update(['status' => 'void']);
                }

                $order->update(['status' => $next]);
                OrderStatusHistory::query()->create([
                    'order_id' => $order->id,
                    'from_status' => $current,
                    'to_status' => $next,
                    'actor_id' => $request->user()->id,
                    'notes' => $data['notes'] ?? ($next === OrderStatus::ReadyForPickup ? 'Seller marked the order ready for pickup.' : null),
                    'created_at' => now(),
                ]);

                $shipmentStatus = match ($next) {
                    OrderStatus::Confirmed, OrderStatus::Preparing => ShipmentStatus::Preparing,
                    OrderStatus::ReadyForPickup => ShipmentStatus::Packed,
                    OrderStatus::Cancelled => ShipmentStatus::Cancelled,
                    default => null,
                };
                if ($shipmentStatus) {
                    app(ShipmentService::class)->recordOrderMilestone(
                        $order->fresh(),
                        $request->user(),
                        $shipmentStatus,
                        $shipmentStatus->defaultTitle(),
                        null,
                        $next === OrderStatus::ReadyForPickup ? 'Seller marked the order ready for pickup.' : ($data['notes'] ?? null),
                        ['skip_proof' => true],
                    );
                }

                if ($next === OrderStatus::ReadyForPickup) {
                    $dashTracking = $order->fresh()->shipment?->tracking_number ?? ('JEP'.strtoupper(Str::random(10)));
                    $parcel = Parcel::query()->firstOrCreate(
                        ['order_id' => $order->id],
                        [
                            'tracking_number' => $dashTracking,
                            'status' => OrderStatus::ReadyForPickup,
                        ]
                    );
                    $parcel->update(['status' => OrderStatus::ReadyForPickup]);
                    PickupAssignment::query()->firstOrCreate(
                        ['parcel_id' => $parcel->id],
                        ['seller_id' => $order->seller_id, 'status' => 'pending']
                    );
                }

                return $order->fresh(['items', 'statusHistories.actor', 'parcel.deliveryAssignment.courier', 'shipment']);
            });
        } catch (ConflictHttpException $exception) {
            return response()->json(['message' => $exception->getMessage()], 409);
        }

        return response()->json([
            'message' => 'Order status updated.',
            'order' => $this->orderPayload($order),
        ]);
    }

    private function orderPayload(Order $order): array
    {
        $address = $order->shipping_address_snapshot ?? [];
        $deliveryAssignment = $order->parcel?->deliveryAssignment;

        return [
            'id' => $order->id,
            'order_number' => $order->order_number,
            'status' => $order->status,
            'subtotal' => (float) $order->subtotal,
            'shipping_fee' => (float) $order->shipping_fee,
            'discount' => (float) $order->discount,
            'total' => (float) $order->total,
            'payment_method' => 'COD',
            'delivery_address' => $order->shipping_address_snapshot
                ? implode(', ', array_filter([
                    $order->shipping_address_snapshot['street_line'] ?? null,
                    $order->shipping_address_snapshot['barangay_name'] ?? null,
                    $order->shipping_address_snapshot['city_name'] ?? null,
                    $order->shipping_address_snapshot['province_name'] ?? null,
                    $order->shipping_address_snapshot['region_name'] ?? null,
                    $order->shipping_address_snapshot['country_name'] ?? null,
                ]))
                : '',
            'placed_at' => $order->placed_at?->toISOString(),
            'created_at' => $order->created_at?->toISOString(),
            'tracking_number' => $order->shipment?->tracking_number ?? $order->parcel?->tracking_number,
            'shipment_status' => $order->shipment?->status?->value ?? $order->parcel?->status?->value,
            'assigned_rider' => $deliveryAssignment?->courier ? [
                'name' => $deliveryAssignment->courier->name,
                'phone' => $deliveryAssignment->courier->phone,
            ] : null,
            'delivery_coordinates' => [
                'latitude' => $address['latitude'] ?? null,
                'longitude' => $address['longitude'] ?? null,
            ],
            'tracking_history' => $order->statusHistories->map(fn ($history) => [
                'status' => $history->to_status?->value,
                'notes' => $history->notes,
                'actor' => $history->actor?->name,
                'timestamp' => $history->created_at?->toISOString(),
            ])->values(),
            'items' => $order->items->map(fn ($i) => [
                'product_id' => $i->product_id,
                'product_name' => $i->name,
                'sku' => $i->sku,
                'quantity' => $i->quantity,
                'stock_before' => $i->stock_before,
                'stock_after' => $i->stock_after,
                'price' => (float) $i->unit_price,
                'subtotal' => (float) $i->subtotal,
                'rating' => $i->rating ?? null,
                'review' => $i->review ?? null,
            ])->values(),
        ];
    }
}
