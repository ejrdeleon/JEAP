<?php

namespace Tests\Feature;

use App\Enums\OrderStatus;
use App\Enums\ShipmentStatus;
use App\Enums\UserStatus;
use App\Events\ShipmentMilestoneUpdated;
use App\Models\Order;
use App\Models\Shipment;
use App\Models\User;
use App\Services\ShipmentService;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Tests\TestCase;

class JeapDashTrackingTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
    }

    public function test_initialize_shipment_creates_jd_tracking_and_placed_checkpoint(): void
    {
        [$buyer, $order] = $this->makeOrder();

        $shipment = app(ShipmentService::class)->initializeShipment($order);

        $this->assertMatchesRegularExpression('/^JD-\d{8}-[A-Z0-9]{5}$/', $shipment->tracking_number);
        $this->assertSame(ShipmentStatus::OrderPlaced, $shipment->status);
        $this->assertSame('JEAP Dash', $shipment->courier_name);
        $this->assertSame(0, $shipment->progress_bar_step);
        $this->assertSame('Order is placed', $shipment->checkpoints->first()->title);
        $this->assertSame($shipment->id, app(ShipmentService::class)->initializeShipment($order)->id);
    }

    public function test_buyer_can_open_shopee_style_tracking_page(): void
    {
        [$buyer, $order] = $this->makeOrder();
        app(ShipmentService::class)->initializeShipment($order);

        $this->actingAs($buyer)->get(route('orders.tracking', $order))
            ->assertOk()
            ->assertSee('JEAP Dash')
            ->assertSee('Order is placed')
            ->assertSee('Copy');
    }

    public function test_public_track_lookup_shows_jd_shipment_to_guests_and_redirects_the_buyer(): void
    {
        [$buyer, $order] = $this->makeOrder();
        $shipment = app(ShipmentService::class)->initializeShipment($order);

        $this->get(route('shipping.track', ['tracking_number' => $shipment->tracking_number]))
            ->assertOk()
            ->assertSee($shipment->tracking_number)
            ->assertSee('Order is placed')
            ->assertDontSee($order->shipping_address_snapshot['recipient_name']);

        $this->actingAs($buyer)->get(route('shipping.track', ['tracking_number' => $shipment->tracking_number]))
            ->assertRedirect(route('orders.tracking', $order));
    }

    public function test_stranger_cannot_open_order_tracking(): void
    {
        [, $order] = $this->makeOrder();
        $stranger = User::factory()->create(['status' => UserStatus::Active]);
        $stranger->assignRole('buyer');

        $this->actingAs($stranger)->get(route('orders.tracking', $order))->assertForbidden();
    }

    public function test_dash_checkpoint_api_records_hub_scan_and_delivery_proof(): void
    {
        Storage::fake('local');
        Storage::fake('public');
        Event::fake([ShipmentMilestoneUpdated::class]);

        [$buyer, $order] = $this->makeOrder();
        $shipment = app(ShipmentService::class)->initializeShipment($order);
        $hub = User::factory()->create(['status' => UserStatus::Active]);
        $hub->assignRole('logistics');
        $rider = User::factory()->create(['status' => UserStatus::Active]);
        $rider->assignRole('courier');

        $this->actingAs($hub, 'sanctum')->post('/api/dash/shipments/'.$shipment->tracking_number.'/checkpoint', [
            'status' => ShipmentStatus::AtHub->value,
            'title' => 'Parcel arrived at delivery hub: Pagsanjan Hub',
            'location' => 'Pagsanjan Delivery Hub',
            'notes' => 'Sorted for last-mile',
        ])->assertCreated()
            ->assertJsonPath('shipment.status', 'at_hub')
            ->assertJsonPath('shipment.current_hub', 'Pagsanjan Delivery Hub');

        $stranger = User::factory()->create(['status' => UserStatus::Active]);
        $stranger->assignRole('courier');
        $this->actingAs($stranger, 'sanctum')->post('/api/dash/shipments/'.$shipment->tracking_number.'/checkpoint', [
            'status' => ShipmentStatus::OutForDelivery->value,
            'location' => 'Pagsanjan Delivery Hub',
        ])->assertForbidden();

        $shipment->update(['courier_id' => $rider->id]);

        $this->actingAs($rider, 'sanctum')->post('/api/dash/shipments/'.$shipment->tracking_number.'/checkpoint', [
            'status' => ShipmentStatus::OutForDelivery->value,
            'location' => 'Pagsanjan Delivery Hub',
            'notes' => 'Assigned to driver: '.$rider->name,
        ])->assertCreated()
            ->assertJsonPath('shipment.status', 'out_for_delivery');

        $this->actingAs($rider, 'sanctum')->post('/api/dash/shipments/'.$shipment->tracking_number.'/checkpoint', [
            'status' => ShipmentStatus::Delivered->value,
            'proof_of_delivery' => $this->fakeJpeg('pod.jpg'),
            'recipient_name' => 'Demo Buyer',
        ])->assertCreated()
            ->assertJsonPath('shipment.status', 'delivered')
            ->assertJsonPath('shipment.progress_step', 3);

        Event::assertDispatched(ShipmentMilestoneUpdated::class);
        $fresh = $shipment->fresh();
        $this->assertNotNull($fresh->proof_of_delivery);
        $this->assertSame(OrderStatus::Delivered, $order->fresh()->status);
        Storage::disk('local')->assertExists($fresh->proof_of_delivery);
        Storage::disk('public')->assertMissing($fresh->proof_of_delivery);
        $this->assertStringContainsString('/media/proof-of-delivery/', (string) $fresh->proof_of_delivery_url);

        $this->actingAs($buyer)->get(route('media.proof', $fresh))->assertOk();
        $stranger = User::factory()->create(['status' => UserStatus::Active]);
        $stranger->assignRole('buyer');
        $this->actingAs($stranger)->get(route('media.proof', $fresh))->assertForbidden();
        $this->actingAs($buyer)->get(route('orders.tracking', $order))
            ->assertOk()
            ->assertSee('View Proof of Delivery')
            ->assertSee('Delivered on');
    }

    public function test_buyer_cannot_post_dash_checkpoint(): void
    {
        [, $order] = $this->makeOrder();
        $shipment = app(ShipmentService::class)->initializeShipment($order);
        $buyer = $order->buyer;
        $buyer->assignRole('buyer');

        $this->actingAs($buyer, 'sanctum')->post('/api/dash/shipments/'.$shipment->tracking_number.'/checkpoint', [
            'status' => ShipmentStatus::AtHub->value,
        ])->assertForbidden();
    }

    private function fakeJpeg(string $name): UploadedFile
    {
        $jpeg = base64_decode('
            /9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAkGBwgHBgkIBwgKCgkLDRYPDQwMDRsUFRAWIB0iIiAd
            Hx8kKDQsJCYxJx8fLT0tMTU3Ojo6Iys/RD84QzQ5OjcBCgoKDQwNGg8PGjclHyU3Nzc3Nzc3Nzc3
            Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3N//AABEIAAEAAQMBIgACEQED
            EQH/xAAUAAEAAAAAAAAAAAAAAAAAAAAK/8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAwDAQACEQMR
            AD8AKj//2Q==
        ');

        return UploadedFile::fake()->createWithContent($name, $jpeg);
    }

    private function makeOrder(): array
    {
        $buyer = User::factory()->create(['status' => UserStatus::Active]);
        $buyer->assignRole('buyer');
        $seller = User::factory()->create(['status' => UserStatus::Active]);
        $seller->assignRole('seller');
        $order = Order::query()->create([
            'checkout_group_id' => (string) Str::uuid(),
            'order_number' => 'JEAP-DASH-1',
            'buyer_id' => $buyer->id,
            'seller_id' => $seller->id,
            'status' => OrderStatus::Placed,
            'subtotal' => 100,
            'shipping_fee' => 50,
            'discount' => 0,
            'total' => 150,
            'shipping_address_snapshot' => ['recipient_name' => 'Demo Buyer'],
            'placed_at' => now(),
        ]);

        return [$buyer, $order];
    }
}
