<?php

namespace App\Enums;

enum VehicleType: string
{
    case TwoWheels = '2_wheels';
    case FourWheels = '4_wheels';

    public function label(): string
    {
        return match ($this) {
            self::TwoWheels => '2 wheels',
            self::FourWheels => '4 wheels',
        };
    }

    public static function options(): array
    {
        return [
            self::TwoWheels->value => self::TwoWheels->label(),
            self::FourWheels->value => self::FourWheels->label(),
        ];
    }

    public static function values(): array
    {
        return array_column(self::cases(), 'value');
    }

    public static function fromStored(null|string|self $value): ?self
    {
        if ($value instanceof self) {
            return $value;
        }

        $normalized = strtolower(trim((string) $value));
        $normalized = str_replace(['-', ' '], '_', $normalized);

        return match ($normalized) {
            '2_wheels', 'two_wheels', '2wheels', 'motorcycle', 'bike', 'scooter' => self::TwoWheels,
            '4_wheels', 'four_wheels', '4wheels', 'car', 'van', 'truck', 'automobile' => self::FourWheels,
            default => self::tryFrom((string) $value),
        };
    }
}
