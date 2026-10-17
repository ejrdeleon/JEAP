<?php

namespace App\Http\Controllers\Buyer;

use App\Commerce\ShipmentWorkflow;
use App\Enums\OrderStatus;
use App\Enums\PaymentStatus;
use App\Http\Controllers\Controller;
use App\Models\Address;
use App\Models\Order;
use App\Models\OrderStatusHistory;
use App\Models\ProductVariant;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;

class DashboardController extends Controller
{
    public function home(): View
    {
        $buyerId = auth()->id() ?? 0;
        $baseQuery = Order::query()->where('buyer_id', $buyerId);
        $orders = (clone $baseQuery)
            ->with(['items', 'seller', 'parcel'])
            ->latest('placed_at')
            ->paginate(5);
        $activeOrderCount = (clone $baseQuery)
            ->whereNotIn('status', [OrderStatus::Completed->value, OrderStatus::Cancelled->value, OrderStatus::Returned->value])
            ->count();

        return view('buyer.home', [
            'figma' => '01_Buyer_Home 1',
            'orders' => $orders,
            'totalOrderCount' => $orders->total(),
            'activeOrderCount' => $activeOrderCount,
        ]);
    }

    public function addresses(): View
    {
        return view('buyer.addresses', [
            'addresses' => request()->user()->addresses()->latest()->get(),
            'mapsKey' => config('services.google.maps_browser_key'),
        ]);
    }

    public function storeAddress(Request $request): RedirectResponse
    {
        $data = $request->validate($this->addressRules());
        $this->saveAddress($request, $data);

        return back()->with('toast', 'Delivery address saved.');
    }

    public function updateAddress(Request $request, int $address): RedirectResponse
    {
        $address = $request->user()->addresses()->findOrFail($address);
        $data = $request->validate($this->addressRules());
        $this->saveAddress($request, $data, $address);

        return back()->with('toast', 'Delivery address updated.');
    }

    public function deleteAddress(Request $request, int $address): RedirectResponse
    {
        $request->user()->addresses()->findOrFail($address)->delete();

        return back()->with('toast', 'Delivery address removed.');
    }

    public function search(Request $request): RedirectResponse
    {
        $filters = $request->only(['q', 'category', 'min_price', 'max_price', 'sort', 'in_stock']);

        return redirect()->route('products.index', array_filter($filters, fn ($value) => $value !== null && $value !== ''));
    }

    public function cart(): RedirectResponse
    {
        return redirect()->route('cart.index');
    }

    public function checkout(): RedirectResponse
    {
        return redirect()->route('checkout');
    }

    public function track(Order $order): View
    {
        abort_unless($order->buyer_id === auth()->id() || auth()->user()?->hasRole('admin'), 403);

        $order->load([
            'items',
            'seller',
            'statusHistories.actor',
            'parcel.pickupAssignment.courier',
            'parcel.deliveryAssignment.courier',
            'parcel.scans.scannedBy',
        ]);
        $events = $order->statusHistories->map(fn ($history) => [
            'label' => str($history->to_status?->value ?? 'Order update')->replace('_', ' ')->title()->toString(),
            'notes' => $history->notes,
            'actor' => $history->actor?->name,
            'at' => $history->created_at,
        ])->concat($order->parcel?->scans->map(fn ($scan) => [
            'label' => 'Shipment update',
            'notes' => $scan->notes,
            'actor' => $scan->scannedBy?->name,
            'at' => $scan->created_at,
        ]) ?? collect())->sortBy('at')->values();

        return view('buyer.track', ['order' => $order, 'events' => $events]);
    }

    public function confirmReceived(Request $request, Order $order, ShipmentWorkflow $workflow): RedirectResponse
    {
        abort_unless($order->buyer_id === $request->user()->id, 404);

        DB::transaction(function () use ($order, $request, $workflow): void {
            $lockedOrder = Order::query()->whereKey($order->id)->lockForUpdate()->firstOrFail();
            abort_unless($lockedOrder->status === OrderStatus::Delivered, 409, 'Only delivered orders can be confirmed.');
            $parcel = $lockedOrder->parcel()->lockForUpdate()->firstOrFail();
            $workflow->transition($lockedOrder, $parcel, OrderStatus::Completed, $request->user(), 'Buyer confirmed receipt of the order.');
        });

        return back()->with('status', 'Receipt confirmed. Thank you for shopping with JEAP.');
    }

    public function cancelOrder(Request $request, Order $order): RedirectResponse
    {
        abort_unless($order->buyer_id === $request->user()->id, 404);
        $data = $request->validate([
            'reason' => ['required', 'string', 'min:10', 'max:300'],
        ]);

        DB::transaction(function () use ($order, $request, $data): void {
            $lockedOrder = Order::query()->whereKey($order->id)->lockForUpdate()->firstOrFail();
            abort_unless(in_array($lockedOrder->status, [OrderStatus::Placed, OrderStatus::Confirmed, OrderStatus::Preparing], true), 409, 'This order can no longer be cancelled online.');
            $from = $lockedOrder->status;

            foreach ($lockedOrder->items as $item) {
                ProductVariant::query()->whereKey($item->product_variant_id)->increment('stock', $item->quantity);
            }
            $lockedOrder->payments()->where('status', PaymentStatus::Pending->value)->update(['status' => PaymentStatus::Cancelled->value]);
            $lockedOrder->commission()->update(['status' => 'void']);
            $lockedOrder->update([
                'status' => OrderStatus::Cancelled,
                'cancellation_reason' => trim($data['reason']),
            ]);
            OrderStatusHistory::query()->create([
                'order_id' => $lockedOrder->id,
                'from_status' => $from,
                'to_status' => OrderStatus::Cancelled,
                'actor_id' => $request->user()->id,
                'notes' => 'Buyer cancelled the order: '.trim($data['reason']),
                'created_at' => now(),
            ]);
        });

        return back()->with('status', 'Your order was cancelled.');
    }

    private function addressRules(): array
    {
        return [
            'label' => ['nullable', 'string', 'max:64'],
            'recipient_name' => ['required', 'string', 'max:255'],
            'phone' => ['required', 'string', 'max:32'],
            'country_code' => ['nullable', 'string', 'size:2', 'alpha'],
            'country_name' => ['nullable', 'string', 'max:255'],
            'street_line' => ['required', 'string', 'max:255'],
            'city_name' => ['required', 'string', 'max:255'],
            'region_code' => ['nullable', 'string', 'regex:/^\d{1,16}$/'],
            'province_code' => ['nullable', 'string', 'regex:/^\d{1,16}$/'],
            'city_code' => ['nullable', 'string', 'regex:/^\d{1,16}$/'],
            'barangay_code' => ['nullable', 'string', 'regex:/^\d{1,16}$/'],
            'province_name' => ['nullable', 'string', 'max:255'],
            'region_name' => ['nullable', 'string', 'max:255'],
            'barangay_name' => ['nullable', 'string', 'max:255'],
            'postal_code' => ['nullable', 'string', 'max:16'],
            'latitude' => ['nullable', 'required_with:longitude', 'numeric', 'between:-90,90'],
            'longitude' => ['nullable', 'required_with:latitude', 'numeric', 'between:-180,180'],
            'is_default' => ['sometimes', 'boolean'],
        ];
    }

    private function saveAddress(Request $request, array $data, ?Address $address = null): void
    {
        DB::transaction(function () use ($request, $data, $address): void {
            $makeDefault = (bool) ($data['is_default'] ?? false)
                || (! $address && ! $request->user()->addresses()->exists());

            if ($makeDefault) {
                $request->user()->addresses()->update(['is_default' => false]);
            }

            $data['is_default'] = $makeDefault;

            if ($address) {
                $address->update($data);
            } else {
                $request->user()->addresses()->create($data);
            }
        });
    }
}
