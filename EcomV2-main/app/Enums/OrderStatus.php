<?php

namespace App\Enums;

enum OrderStatus: string
{
    case Placed = 'PLACED';
    case Confirmed = 'CONFIRMED';
    case Preparing = 'PREPARING';
    case ReadyForPickup = 'READY_FOR_PICKUP';
    case PickedUp = 'PICKED_UP';
    case AtSortingCenter = 'AT_SORTING_CENTER';
    case Sorted = 'SORTED';
    case AssignedToRider = 'ASSIGNED_TO_RIDER';
    case OutForDelivery = 'OUT_FOR_DELIVERY';
    case Delivered = 'DELIVERED';
    case Completed = 'COMPLETED';
    case DeliveryFailed = 'DELIVERY_FAILED';
    case Returned = 'RETURNED';
    case Cancelled = 'CANCELLED';

    public static function pipeline(): array
    {
        return [
            self::Placed,
            self::Confirmed,
            self::Preparing,
            self::ReadyForPickup,
            self::PickedUp,
            self::AtSortingCenter,
            self::Sorted,
            self::AssignedToRider,
            self::OutForDelivery,
            self::Delivered,
            self::Completed,
        ];
    }
}
