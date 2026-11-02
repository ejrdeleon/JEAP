<?php

namespace App\Commerce;

use App\Enums\OrderStatus;
use App\Enums\UserStatus;
use App\Models\DeliveryAssignment;
use App\Models\Order;
use App\Models\Parcel;
use App\Models\ParcelScan;
use App\Models\PickupAssignment;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class CourierAssignmentService
{
    public function assignPickup(Parcel $parcel, int $courierId, User $actor): PickupAssignment
    {
        $courier = $this->activeCourier($courierId);

        return DB::transaction(function () use ($parcel, $courier, $actor): PickupAssignment {
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
                'scanned_by' => $actor->id,
                'location_type' => 'assignment',
                'location_id' => $courier->id,
                'notes' => 'Pickup assigned to '.$courier->name.'.',
            ]);

            return $assignment->fresh(['courier']) ?? $assignment;
        });
    }

    public function assignDelivery(Parcel $parcel, int $courierId, User $actor, ShipmentWorkflow $workflow): DeliveryAssignment
    {
        $courier = $this->activeCourier($courierId);

        return DB::transaction(function () use ($parcel, $courier, $actor, $workflow): DeliveryAssignment {
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

            $workflow->transition($order, $lockedParcel, OrderStatus::AssignedToRider, $actor, 'Delivery assigned to '.$courier->name.'.');
            ParcelScan::query()->create([
                'parcel_id' => $lockedParcel->id,
                'scanned_by' => $actor->id,
                'location_type' => 'assignment',
                'location_id' => $courier->id,
                'notes' => 'Delivery assigned to '.$courier->name.'.',
            ]);

            return $assignment->fresh(['courier']) ?? $assignment;
        });
    }

    private function activeCourier(int $courierId): User
    {
        $courier = User::query()->role('courier')->where('status', UserStatus::Active)->find($courierId);
        if (! $courier) {
            throw ValidationException::withMessages([
                'courier_id' => 'Choose an active courier.',
            ]);
        }

        return $courier;
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
