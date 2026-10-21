<?php

namespace App\Commerce;

use App\Models\ProductVariant;

class InventoryPolicy
{
    public static function minSellableStock(): int
    {
        return (int) config('jeap.min_sellable_stock', 10);
    }

    public static function maxQtyPerProduct(): int
    {
        return (int) config('jeap.max_qty_per_product', 10);
    }

    public static function shippingFee(): float
    {
        return round((float) config('jeap.shipping_fee', 50), 2);
    }

    public static function isSellable(?ProductVariant $variant): bool
    {
        return $variant !== null
            && $variant->is_active
            && $variant->stock >= self::minSellableStock();
    }

    public static function maxPurchasable(?ProductVariant $variant, int $alreadyInCart = 0): int
    {
        if (! self::isSellable($variant)) {
            return 0;
        }

        return max(0, min(self::maxQtyPerProduct(), $variant->stock) - $alreadyInCart);
    }
}
