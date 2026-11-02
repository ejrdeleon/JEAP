<?php

namespace App\Commerce;

use App\Models\PlatformSetting;
use App\Models\ProductVariant;
use Illuminate\Support\Facades\Schema;

class InventoryPolicy
{
    public static function minSellableStock(): int
    {
        return (int) self::setting('min_sellable_stock', config('jeap.min_sellable_stock', 10));
    }

    public static function maxQtyPerProduct(): int
    {
        return (int) self::setting('max_qty_per_product', config('jeap.max_qty_per_product', 10));
    }

    public static function shippingFee(): float
    {
        return round((float) self::setting('shipping_fee', config('jeap.shipping_fee', 50)), 2);
    }

    public static function setMinSellableStock(int $value): int
    {
        PlatformSetting::setValue('min_sellable_stock', (string) $value);

        return $value;
    }

    public static function setMaxQtyPerProduct(int $value): int
    {
        PlatformSetting::setValue('max_qty_per_product', (string) $value);

        return $value;
    }

    public static function setShippingFee(float $value): float
    {
        $normalized = round($value, 2);
        PlatformSetting::setValue('shipping_fee', number_format($normalized, 2, '.', ''));

        return $normalized;
    }

    private static function setting(string $key, mixed $default): mixed
    {
        if (Schema::hasTable('platform_settings')) {
            $stored = PlatformSetting::getValue($key);
            if ($stored !== null) {
                return $stored;
            }
        }

        return $default;
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

    /**
     * @return array{stock_before: int, stock_after: int}
     */
    public static function takeForOrder(ProductVariant $variant, int $quantity): array
    {
        $before = (int) $variant->stock;
        $variant->decrement('stock', $quantity);
        $after = $before - $quantity;
        $variant->stock = $after;

        return [
            'stock_before' => $before,
            'stock_after' => $after,
        ];
    }
}
