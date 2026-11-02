<?php

namespace App\Commerce;

use App\Models\Cart;
use App\Models\User;
use Illuminate\Support\Facades\DB;

class CartMerge
{
    public static function sessionIntoUser(string $sessionId, User $user): void
    {
        DB::transaction(function () use ($sessionId, $user): void {
            $guestCart = Cart::query()->whereNull('user_id')->where('session_id', $sessionId)
                ->with('items.variant')->lockForUpdate()->first();
            if (! $guestCart) {
                return;
            }

            $userCart = Cart::query()->where('user_id', $user->id)->with('items.variant')->lockForUpdate()->first();
            if (! $userCart) {
                foreach ($guestCart->items as $guestItem) {
                    $allowed = InventoryPolicy::maxPurchasable($guestItem->variant, 0);
                    if ($allowed <= 0) {
                        $guestItem->delete();
                        continue;
                    }
                    if ($guestItem->quantity > $allowed) {
                        $guestItem->update(['quantity' => $allowed]);
                    }
                }
                $guestCart->update(['user_id' => $user->id]);

                return;
            }

            foreach ($guestCart->items as $guestItem) {
                $userItem = $userCart->items->firstWhere('product_variant_id', $guestItem->product_variant_id);
                $already = (int) ($userItem?->quantity ?? 0);
                $allowed = InventoryPolicy::maxPurchasable($guestItem->variant, 0);
                $merged = min($allowed, $already + (int) $guestItem->quantity);
                if ($merged <= 0) {
                    $guestItem->delete();
                    $userItem?->delete();
                    continue;
                }
                if ($userItem) {
                    $userItem->update(['quantity' => $merged]);
                    $guestItem->delete();
                } else {
                    $guestItem->update([
                        'cart_id' => $userCart->id,
                        'quantity' => $merged,
                    ]);
                }
            }

            $guestCart->delete();
        });
    }
}
