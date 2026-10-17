<?php

namespace Tests\Feature;

use App\Enums\OrderStatus;
use App\Enums\UserStatus;
use App\Models\Order;
use App\Models\Parcel;
use App\Models\ParcelScan;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Tests\TestCase;

class ShippingPublicPagesTest extends TestCase
{
    use RefreshDatabase;

    public function test_shipping_home_renders_real_tracking_navigation(): void
    {
        $this->get(route('shipping.home'))
            ->assertOk()
            ->assertSee('Your order, on its way.')
            ->assertSee(route('shipping.track'))
            ->assertSee('data-figma="01_Home 1"', false)
            ->assertDontSee('Logistics public cluster');
    }

    public function test_public_tracking_shows_recorded_events_without_private_address_or_scan_notes(): void
    {
        [$order, $parcel] = $this->makeShipment();
        $order->statusHistories()->create([
            'from_status' => OrderStatus::OutForDelivery,
            'to_status' => OrderStatus::Delivered,
            'notes' => 'Private status note should not be shown',
            'created_at' => now()->subMinute(),
        ]);
        ParcelScan::query()->create([
            'parcel_id' => $parcel->id,
            'location_type' => 'hub',
            'notes' => 'Private scan note should not be shown',
        ]);

        $this->get(route('shipping.track', ['tracking_number' => $parcel->tracking_number]))
            ->assertOk()
            ->assertSee('Track Shipment')
            ->assertSee('Delivered')
            ->assertSee('Shipment received at logistics hub')
            ->assertDontSee('Private status note')
            ->assertDontSee('Private scan note')
            ->assertDontSee('12 Sample Street')
            ->assertSee('For your privacy');
    }

    public function test_tracking_requires_an_existing_tracking_number(): void
    {
        $this->get(route('shipping.track', ['tracking_number' => 'UNKNOWN123']))
            ->assertNotFound();
    }

    private function makeShipment(): array
    {
        $buyer = User::factory()->create(['status' => UserStatus::Active]);
        $seller = User::factory()->create(['status' => UserStatus::Active]);
        $order = Order::query()->create([
            'checkout_group_id' => (string) Str::uuid(),
            'order_number' => 'JEP-SHIP-TEST',
            'buyer_id' => $buyer->id,
            'seller_id' => $seller->id,
            'status' => OrderStatus::Delivered,
            'subtotal' => 500,
            'shipping_fee' => 0,
            'discount' => 0,
            'total' => 500,
            'shipping_address_snapshot' => ['street_line' => '12 Sample Street'],
            'placed_at' => now()->subHour(),
        ]);
        $parcel = Parcel::query()->create([
            'order_id' => $order->id,
            'tracking_number' => 'JEPTRACK0001',
            'status' => OrderStatus::Delivered,
        ]);

        return [$order, $parcel];
    }
}
