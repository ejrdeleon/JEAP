<?php

namespace App\Commerce;

use App\Models\Commission;
use App\Models\Order;
use App\Models\PlatformSetting;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class CommissionService
{
    public static function rate(): float
    {
        $stored = null;
        if (Schema::hasTable('platform_settings')) {
            $stored = PlatformSetting::getValue('commission_rate');
        }

        $rate = $stored !== null ? (float) $stored : (float) config('jeap.commission_rate', 20);

        return round($rate, 2);
    }

    public static function setRate(float $rate): float
    {
        $normalized = round($rate, 2);
        PlatformSetting::setValue('commission_rate', number_format($normalized, 2, '.', ''));

        return $normalized;
    }

    public function record(Order $order): Commission
    {
        return DB::transaction(function () use ($order): Commission {
            $lockedOrder = Order::query()->whereKey($order->id)->lockForUpdate()->firstOrFail();
            $existing = Commission::query()->where('order_id', $lockedOrder->id)->first();

            if ($existing) {
                return $existing;
            }

            $rate = self::rate();
            $amount = self::amountForSubtotal((float) $lockedOrder->subtotal, $rate);

            return Commission::query()->create([
                'order_id' => $lockedOrder->id,
                'seller_id' => $lockedOrder->seller_id,
                'rate' => $rate,
                'amount' => $amount,
                'status' => 'pending',
                'accrued_at' => now(),
            ]);
        });
    }

    public static function amountForSubtotal(float $subtotal, ?float $rate = null): float
    {
        $rate ??= self::rate();

        return round($subtotal * $rate / 100, 2);
    }
}
