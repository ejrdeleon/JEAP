<?php

namespace App\Http\Controllers\Logistics;

use App\Commerce\ShipmentWorkflow;
use App\Enums\OrderStatus;
use App\Enums\UserStatus;
use App\Http\Controllers\Controller;
use App\Models\DeliveryAssignment;
use App\Models\Order;
use App\Models\Parcel;
use App\Models\ParcelScan;
use App\Models\PickupAssignment;
use App\Models\User;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;

class ShipmentController extends Controller
{
    public function index(): View
    {
        $shippingStatuses = array_map(
            fn (OrderStatus $status) => $status->value,
            array_slice(OrderStatus::pipeline(), 3)
        );
        $shippingStatuses[] = OrderStatus::DeliveryFailed->value;
        $shippingStatuses[] = OrderStatus::Returned->value;

        $busyPickup = PickupAssignment::query()->whereNotNull('courier_id')
            ->whereIn('status', ['pending', 'accepted'])->pluck('courier_id');
        $busyDelivery = DeliveryAssignment::query()->whereNotNull('courier_id')
            ->whereIn('status', ['pending', 'accepted', 'out_for_delivery'])->pluck('courier_id');
        $availableCourierIds = $busyPickup->merge($busyDelivery)->unique()->values();

        return view('logistics.dashboard', [
            'orders' => Order::query()->whereIn('status', $shippingStatuses)
                ->whereHas('parcel')
                ->with(['buyer', 'seller', 'parcel.pickupAssignment.courier', 'parcel.deliveryAssignment.courier'])
                ->latest('placed_at')->paginate(25),
            'couriers' => User::query()->role('courier')->where('status', UserStatus::Active)
                ->whereNotIn('id', $availableCourierIds)->orderBy('first_name')->get(),
        ]);
    }

    public function assignPickup(Request $request, Parcel $parcel): RedirectResponse
    {
        $data = $request->validate(['courier_id' => ['required', 'integer', 'exists:users,id']]);
        $courier = User::query()->role('courier')->where('status', UserStatus::Active)
            ->findOrFail($data['courier_id']);

        DB::transaction(function () use ($parcel, $courier, $request): void {
            $lockedParcel = Parcel::query()->whereKey($parcel->id)->lockForUpdate()->firstOrFail();
            $order = Order::query()->whereKey($lockedParcel->order_id)->lockForUpdate()->firstOrFail();
            abort_unless($order->status === OrderStatus::ReadyForPickup, 409, 'This order is not waiting for pickup.');
            $this->ensureCourierAvailable($courier, $lockedParcel->id);

            $assignment = PickupAssignment::query()->where('parcel_id', $lockedParcel->id)
                ->lockForUpdate()->first();
            abort_if($assignment && $assignment->status !== 'pending', 409, 'The pickup assignment has already started.');
            abort_if($assignment?->courier_id === $courier->id, 409, 'This rider is already assigned to the pickup.');

            $assignment ??= new PickupAssignment(['parcel_id' => $lockedParcel->id, 'seller_id' => $order->seller_id]);
            $assignment->fill([
                'courier_id' => $courier->id,
                'status' => 'pending',
                'assigned_at' => now(),
            ])->save();

            ParcelScan::query()->create([
                'parcel_id' => $lockedParcel->id,
                'scanned_by' => $request->user()->id,
                'location_type' => 'assignment',
                'location_id' => $courier->id,
                'notes' => 'Pickup assigned to '.$courier->name.'.',
            ]);
        });

        return back()->with('status', 'Pickup rider assigned.');
    }

    public function progress(Request $request, Parcel $parcel, ShipmentWorkflow $workflow): RedirectResponse
    {
        $data = $request->validate(['status' => ['required', 'in:AT_SORTING_CENTER,SORTED']]);

        DB::transaction(function () use ($parcel, $data, $request, $workflow): void {
            $lockedParcel = Parcel::query()->whereKey($parcel->id)->lockForUpdate()->firstOrFail();
            $order = Order::query()->whereKey($lockedParcel->order_id)->lockForUpdate()->firstOrFail();
            $next = OrderStatus::from($data['status']);
            $notes = $next === OrderStatus::AtSortingCenter
                ? 'Parcel received at the sorting center.'
                : 'Parcel sorted and ready for last-mile delivery.';

            $workflow->transition($order, $lockedParcel, $next, $request->user(), $notes);
            $lockedParcel->update(['current_hub_id' => $request->user()->id]);
            ParcelScan::query()->create([
                'parcel_id' => $lockedParcel->id,
                'scanned_by' => $request->user()->id,
                'location_type' => 'hub',
                'location_id' => $request->user()->id,
                'notes' => $notes,
            ]);
        });

        return back()->with('status', 'Shipment status updated.');
    }

    public function assignDelivery(Request $request, Parcel $parcel, ShipmentWorkflow $workflow): RedirectResponse
    {
        $data = $request->validate(['courier_id' => ['required', 'integer', 'exists:users,id']]);
        $courier = User::query()->role('courier')->where('status', UserStatus::Active)
            ->findOrFail($data['courier_id']);

        DB::transaction(function () use ($parcel, $courier, $request, $workflow): void {
            $lockedParcel = Parcel::query()->whereKey($parcel->id)->lockForUpdate()->firstOrFail();
            $order = Order::query()->whereKey($lockedParcel->order_id)->lockForUpdate()->firstOrFail();
            abort_unless(in_array($order->status, [OrderStatus::Sorted, OrderStatus::DeliveryFailed], true), 409, 'Only sorted or failed shipments can be assigned for delivery.');
            $this->ensureCourierAvailable($courier, $lockedParcel->id);

            $assignment = new DeliveryAssignment([
                'parcel_id' => $lockedParcel->id,
                'courier_id' => $courier->id,
                'status' => 'pending',
                'assigned_at' => now(),
            ]);
            $assignment->save();

            $workflow->transition($order, $lockedParcel, OrderStatus::AssignedToRider, $request->user(), 'Delivery assigned to '.$courier->name.'.');
            ParcelScan::query()->create([
                'parcel_id' => $lockedParcel->id,
                'scanned_by' => $request->user()->id,
                'location_type' => 'assignment',
                'location_id' => $courier->id,
                'notes' => 'Delivery assigned to '.$courier->name.'.',
            ]);
        });

        return back()->with('status', 'Delivery rider assigned.');
    }

    private function ensureCourierAvailable(User $courier, int $exceptParcelId): void
    {
        $busyPickup = PickupAssignment::query()->where('courier_id', $courier->id)
            ->where('parcel_id', '!=', $exceptParcelId)->whereIn('status', ['pending', 'accepted'])->exists();
        $busyDelivery = DeliveryAssignment::query()->where('courier_id', $courier->id)
            ->whereIn('status', ['pending', 'accepted', 'out_for_delivery'])->exists();

        abort_if($busyPickup || $busyDelivery, 409, 'This rider already has an active assignment.');
    }
}
