<?php

namespace Tests\Unit;

use App\Commerce\CommissionService;
use App\Commerce\InventoryPolicy;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CommissionCalculationTest extends TestCase
{
    use RefreshDatabase;

    public function test_default_rate_is_twenty_percent_of_merchandise_subtotal_not_shipping(): void
    {
        $this->assertEquals(20.0, CommissionService::rate());
        $this->assertEquals(2.40, CommissionService::amountForSubtotal(12.00));
        $this->assertEquals(195.60, CommissionService::amountForSubtotal(978.00));
        $this->assertEquals(50.0, InventoryPolicy::shippingFee());
        $withShipping = CommissionService::amountForSubtotal(12.00 + InventoryPolicy::shippingFee(), 20);
        $shippingCut = CommissionService::amountForSubtotal(InventoryPolicy::shippingFee(), 20);
        $this->assertEqualsWithDelta(2.40, $withShipping - $shippingCut, 0.001);
    }

    public function test_rounding_zero_and_updated_rate(): void
    {
        $this->assertSame(0.0, CommissionService::amountForSubtotal(0));
        $this->assertSame(0.01, CommissionService::amountForSubtotal(0.05, 20));
        CommissionService::setRate(25);
        $this->assertSame(25.0, CommissionService::rate());
        $this->assertSame(3.00, CommissionService::amountForSubtotal(12.00));
    }
}
