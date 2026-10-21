<?php

namespace App\Commerce;

use App\Models\Commission;
use App\Models\Order;
use Illuminate\Support\Facades\DB;

class CommissionService
{
    public static function rate(): float
    {
        return (float) config('jeap.commission_rate', 20);
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
            $amount = round((float) $lockedOrder->subtotal * $rate / 100, 2);

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
}
