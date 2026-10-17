<?php

namespace App\Commerce;

use App\Enums\OrderStatus;
use App\Models\Order;
use App\Models\OrderStatusHistory;
use App\Models\Parcel;
use App\Models\User;
use Symfony\Component\HttpKernel\Exception\ConflictHttpException;

class ShipmentWorkflow
{
    private const TRANSITIONS = [
        'READY_FOR_PICKUP' => [OrderStatus::PickedUp],
        'PICKED_UP' => [OrderStatus::AtSortingCenter],
        'AT_SORTING_CENTER' => [OrderStatus::Sorted],
        'SORTED' => [OrderStatus::AssignedToRider],
        'DELIVERY_FAILED' => [OrderStatus::AssignedToRider],
        'ASSIGNED_TO_RIDER' => [OrderStatus::OutForDelivery],
        'OUT_FOR_DELIVERY' => [OrderStatus::Delivered, OrderStatus::DeliveryFailed],
        'DELIVERED' => [OrderStatus::Completed],
    ];

    public function transition(Order $order, Parcel $parcel, OrderStatus $next, User $actor, string $notes): void
    {
        $current = $order->status;
        if (! in_array($next, self::TRANSITIONS[$current->value] ?? [], true)) {
            throw new ConflictHttpException('This shipment status transition is not allowed.');
        }

        $order->update(['status' => $next]);
        $parcel->update(['status' => $next]);

        OrderStatusHistory::query()->create([
            'order_id' => $order->id,
            'from_status' => $current,
            'to_status' => $next,
            'actor_id' => $actor->id,
            'notes' => $notes,
            'created_at' => now(),
        ]);
    }
}
