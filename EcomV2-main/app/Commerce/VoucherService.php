<?php

namespace App\Commerce;

use App\Models\Order;
use App\Models\User;
use App\Models\Voucher;
use Illuminate\Validation\ValidationException;

class VoucherService
{
    public function findUsable(?string $code, User $buyer, int $sellerId, float $subtotal): ?Voucher
    {
        $code = strtoupper(trim((string) $code));
        if ($code === '') {
            return null;
        }

        $voucher = Voucher::query()->whereRaw('UPPER(code) = ?', [$code])->first();
        if (! $voucher) {
            throw ValidationException::withMessages([
                'voucher_code' => 'That voucher code was not found.',
            ]);
        }
        if ($voucher->seller_id && (int) $voucher->seller_id !== $sellerId) {
            return null;
        }
        if (! $voucher->isUsableBy($buyer, $subtotal)) {
            throw ValidationException::withMessages([
                'voucher_code' => 'That voucher cannot be used on this order.',
            ]);
        }

        return $voucher;
    }

    public function redeem(Voucher $voucher, Order $order, User $buyer, float $discount): void
    {
        $voucher->increment('used_count');
        $voucher->usages()->create([
            'order_id' => $order->id,
            'buyer_id' => $buyer->id,
            'discount_applied' => $discount,
        ]);
    }
}
