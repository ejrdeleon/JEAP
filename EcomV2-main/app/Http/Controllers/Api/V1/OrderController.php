<?php

namespace App\Http\Controllers\Api\V1;

use App\Commerce\CommissionService;
use App\Commerce\InventoryPolicy;
use App\Commerce\ShipmentWorkflow;
use App\Enums\OrderStatus;
use App\Http\Controllers\Controller;
use App\Models\Cart;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\OrderStatusHistory;
use App\Models\Payment;
use App\Models\ProductVariant;
use App\Models\Review;
use App\Payments\PaymentGateway;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class OrderController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = Order::query()->with(['items', 'statusHistories.actor', 'parcel.deliveryAssignment.courier'])->latest('placed_at');

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
        $query = Order::query()->where('order_number', $orderNumber)->with(['items', 'statusHistories.actor', 'parcel.deliveryAssignment.courier']);

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
                    $variant->decrement('stock', $item->quantity);
                    $item->unit_price = $variant->price;
                    $item->setRelation('variant', $variant);
                }

                $subtotal = $sellerItems->sum(fn ($i) => $i->unit_price * $i->quantity);
                $fee = InventoryPolicy::shippingFee();
                $discount = 0.00;

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

                foreach ($sellerItems as $item) {
                    OrderItem::create([
                        'order_id' => $order->id,
                        'product_id' => $item->variant->product_id,
                        'product_variant_id' => $item->product_variant_id,
                        'name' => $item->variant->product->name,
                        'sku' => $item->variant->sku,
                        'quantity' => $item->quantity,
                        'unit_price' => $item->unit_price,
                        'subtotal' => $item->unit_price * $item->quantity,
                    ]);
                }

                OrderStatusHistory::create([
                    'order_id' => $order->id,
                    'to_status' => OrderStatus::Placed->value,
                    'created_at' => now(),
                ]);

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
            'tracking_number' => $order->parcel?->tracking_number,
            'shipment_status' => $order->parcel?->status?->value,
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
                'price' => (float) $i->unit_price,
                'subtotal' => (float) $i->subtotal,
                'rating' => $i->rating ?? null,
                'review' => $i->review ?? null,
            ])->values(),
        ];
    }
}
