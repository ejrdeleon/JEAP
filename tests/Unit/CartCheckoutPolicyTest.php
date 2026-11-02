<?php

namespace Tests\Unit;

use App\Commerce\InventoryPolicy;
use App\Models\ProductVariant;
use Tests\TestCase;

class CartCheckoutPolicyTest extends TestCase
{
    public function test_cart_caps_quantity_at_ten_and_requires_ten_units_to_sell(): void
    {
        $this->assertSame(10, InventoryPolicy::minSellableStock());
        $this->assertSame(10, InventoryPolicy::maxQtyPerProduct());

        $unsellable = new ProductVariant(['is_active' => true, 'stock' => 9]);
        $this->assertFalse(InventoryPolicy::isSellable($unsellable));
        $this->assertSame(0, InventoryPolicy::maxPurchasable($unsellable));

        $sellable = new ProductVariant(['is_active' => true, 'stock' => 20]);
        $this->assertTrue(InventoryPolicy::isSellable($sellable));
        $this->assertSame(10, InventoryPolicy::maxPurchasable($sellable));
        $this->assertSame(7, InventoryPolicy::maxPurchasable($sellable, 3));
        $this->assertSame(0, InventoryPolicy::maxPurchasable($sellable, 10));
    }
}
