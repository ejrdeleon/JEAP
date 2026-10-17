<?php

namespace App\Commerce;

use App\Models\Commission;
use App\Models\Order;
use Illuminate\Support\Facades\DB;

class CommissionService
{
    public const RATE = 10.00;

    public function record(Order $order): Commission
    {
        return DB::transaction(function () use ($order): Commission {
            $lockedOrder = Order::query()->whereKey($order->id)->lockForUpdate()->firstOrFail();
            $existing = Commission::query()->where('order_id', $lockedOrder->id)->first();

            if ($existing) {
                return $existing;
            }

            $amount = round((float) $lockedOrder->total * self::RATE / 100, 2);

            return Commission::query()->create([
                'order_id' => $lockedOrder->id,
                'seller_id' => $lockedOrder->seller_id,
                'rate' => self::RATE,
                'amount' => $amount,
                'status' => 'pending',
                'accrued_at' => now(),
            ]);
        });
    }
}
