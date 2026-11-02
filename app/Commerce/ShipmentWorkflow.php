<?php

namespace App\Commerce;

use App\Commerce\ChatService;
use App\Enums\OrderStatus;
use App\Enums\ShipmentStatus;
use App\Models\Order;
use App\Models\OrderStatusHistory;
use App\Models\Parcel;
use App\Models\User;
use App\Notifications\OrderStatusNotification;
use App\Services\ShipmentService;
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

        $order->loadMissing(['buyer', 'seller', 'parcel.deliveryAssignment.courier', 'parcel.pickupAssignment.courier']);
        if ($order->buyer?->wantsNotification('order_updates')) {
            $order->buyer->notify(new OrderStatusNotification(
                $order,
                'Order '.$order->order_number,
                $notes !== '' ? $notes : 'Status updated to '.str($next->value)->replace('_', ' ')->lower().'.',
            ));
        }

        $courier = $order->parcel?->deliveryAssignment?->courier
            ?? $order->parcel?->pickupAssignment?->courier;
        if ($courier && in_array($next, [OrderStatus::AssignedToRider, OrderStatus::OutForDelivery, OrderStatus::PickedUp], true)) {
            app(ChatService::class)->forOrder($order, $courier);
        }

        $dashStatus = match ($next) {
            OrderStatus::PickedUp => ShipmentStatus::PickedUp,
            OrderStatus::AtSortingCenter => ShipmentStatus::AtHub,
            OrderStatus::Sorted => ShipmentStatus::InTransit,
            OrderStatus::AssignedToRider, OrderStatus::OutForDelivery => ShipmentStatus::OutForDelivery,
            OrderStatus::Delivered => ShipmentStatus::Delivered,
            OrderStatus::DeliveryFailed => ShipmentStatus::FailedDelivery,
            default => null,
        };
        if ($dashStatus) {
            $hub = in_array($next, [OrderStatus::AtSortingCenter, OrderStatus::Sorted], true)
                ? 'Laguna Central Hub'
                : null;
            $dashNotes = $notes;
            if ($courier && in_array($next, [OrderStatus::AssignedToRider, OrderStatus::OutForDelivery], true)) {
                $dashNotes = 'Assigned to driver: '.$courier->name;
            }
            app(ShipmentService::class)->recordOrderMilestone(
                $order->fresh(),
                $actor,
                $dashStatus,
                $dashStatus->defaultTitle($hub),
                $hub,
                $dashNotes,
                array_filter([
                    'skip_proof' => true,
                    'courier_id' => $courier?->id,
                ]),
            );
        }
    }
}
