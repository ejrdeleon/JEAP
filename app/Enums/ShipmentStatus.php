<?php

namespace App\Enums;

enum ShipmentStatus: string
{
    case OrderPlaced = 'order_placed';
    case Preparing = 'preparing';
    case Packed = 'packed';
    case PickedUp = 'picked_up';
    case InTransit = 'in_transit';
    case AtHub = 'at_hub';
    case OutForDelivery = 'out_for_delivery';
    case Delivered = 'delivered';
    case FailedDelivery = 'failed_delivery';
    case Cancelled = 'cancelled';

    public function label(): string
    {
        return match ($this) {
            self::OrderPlaced => 'Order placed',
            self::Preparing => 'Preparing',
            self::Packed => 'Packed',
            self::PickedUp => 'Picked up',
            self::InTransit => 'In transit',
            self::AtHub => 'At hub',
            self::OutForDelivery => 'Out for delivery',
            self::Delivered => 'Delivered',
            self::FailedDelivery => 'Failed delivery',
            self::Cancelled => 'Cancelled',
        };
    }

    public function defaultTitle(?string $hub = null): string
    {
        $place = $hub ?: 'JEAP Dash hub';

        return match ($this) {
            self::OrderPlaced => 'Order is placed',
            self::Preparing => 'Seller is preparing your parcel',
            self::Packed => 'Parcel packed and ready for JEAP Dash pickup',
            self::PickedUp => 'Parcel picked up by JEAP Dash',
            self::InTransit => 'Parcel is in transit',
            self::AtHub => 'Parcel has arrived at sorting facility: '.$place,
            self::OutForDelivery => 'Parcel is out for delivery',
            self::Delivered => 'Parcel has been delivered',
            self::FailedDelivery => 'Delivery attempt unsuccessful',
            self::Cancelled => 'Shipment cancelled',
        };
    }

    public static function values(): array
    {
        return array_column(self::cases(), 'value');
    }
}
