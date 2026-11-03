<?php

namespace Tests\Feature;

use App\Enums\OrderStatus;
use App\Enums\UserStatus;
use App\Models\Order;
use App\Models\Parcel;
use App\Models\ParcelScan;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Tests\TestCase;

class ShippingPublicPagesTest extends TestCase
{
    use RefreshDatabase;

    public function test_shipping_home_redirects_to_track(): void
    {
        $this->get(route('shipping.home'))
            ->assertRedirect(route('shipping.track'));
        $this->get('/shipping')
            ->assertRedirect(route('shipping.track'));
    }

    public function test_track_page_is_the_shipping_destination_and_prompts_guests_to_log_in(): void
    {
        $this->get(route('shipping.track'))
            ->assertOk()
            ->assertSee('Track your orders')
            ->assertSee('See your current orders live')
            ->assertSee(route('login'))
            ->assertDontSee('Your order, on its way.')
            ->assertDontSee('Logistics public cluster');
    }

    public function test_logged_in_buyer_sees_current_orders_without_private_address(): void
    {
        $this->seed(RoleSeeder::class);
        [$order, $parcel] = $this->makeShipment();

        $this->actingAs($order->buyer)->get(route('shipping.track'))
            ->assertOk()
            ->assertSee('In progress')
            ->assertSee($order->order_number)
            ->assertSee($parcel->tracking_number)
            ->assertSee('Live')
            ->assertDontSee('12 Sample Street');

        $live = $this->actingAs($order->buyer)->get(route('shipping.track.live'))
            ->assertOk()
            ->assertJsonPath('orders.0.order_number', $order->order_number)
            ->assertJsonPath('orders.0.tracking_number', $parcel->tracking_number);
        $this->assertStringNotContainsString('12 Sample Street', $live->getContent());
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
            ->assertSee('Track your orders')
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
            ->assertOk()
            ->assertSee('could not find that tracking number');
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
