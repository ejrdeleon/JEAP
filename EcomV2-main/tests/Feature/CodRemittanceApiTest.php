<?php

namespace Tests\Feature;

use App\Enums\OrderStatus;
use App\Enums\UserStatus;
use App\Models\DeliveryAssignment;
use App\Models\Order;
use App\Models\Parcel;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CodRemittanceApiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
    }

    public function test_rider_can_submit_only_their_delivered_orders_for_logistics_confirmation(): void
    {
        $rider = $this->createUserWithRole('courier');
        $logistics = $this->createUserWithRole('logistics');
        $order = $this->createDeliveredOrder($rider, 'JEP-REMIT-001');

        $this->actingAs($rider, 'sanctum')
            ->postJson('/api/v1/rider/remittances', ['order_ids' => [$order->id]])
            ->assertCreated()
            ->assertJsonStructure(['message', 'remittance_id']);
        $this->actingAs($rider, 'sanctum')
            ->postJson('/api/v1/rider/remittances', ['order_ids' => [$order->id]])
            ->assertUnprocessable();

        $this->assertDatabaseHas('cod_remittances', [
            'courier_id' => $rider->id,
            'logistics_id' => null,
            'amount' => '125.00',
            'status' => 'pending',
        ]);

        $remittanceId = (int) $this->app['db']->table('cod_remittances')->value('id');
        $this->actingAs($logistics, 'sanctum')
            ->getJson('/api/v1/remittances')
            ->assertOk()
            ->assertJsonPath('remittances.0.id', $remittanceId);

        $this->actingAs($logistics, 'sanctum')
            ->postJson("/api/v1/remittances/{$remittanceId}/confirm")
            ->assertOk();

        $this->assertDatabaseHas('cod_remittances', [
            'id' => $remittanceId,
            'logistics_id' => $logistics->id,
            'status' => 'confirmed',
        ]);
    }

    public function test_rider_cannot_submit_an_order_delivered_by_another_rider(): void
    {
        $rider = $this->createUserWithRole('courier');
        $otherRider = $this->createUserWithRole('courier');
        $order = $this->createDeliveredOrder($otherRider, 'JEP-REMIT-002');

        $this->actingAs($rider, 'sanctum')
            ->postJson('/api/v1/rider/remittances', ['order_ids' => [$order->id]])
            ->assertUnprocessable();

        $this->assertDatabaseCount('cod_remittances', 0);
    }

    private function createDeliveredOrder(User $rider, string $orderNumber): Order
    {
        $seller = User::factory()->create(['status' => UserStatus::Active]);
        $buyer = User::factory()->create(['status' => UserStatus::Active]);
        $order = Order::query()->create([
            'checkout_group_id' => fake()->uuid(),
            'order_number' => $orderNumber,
            'buyer_id' => $buyer->id,
            'seller_id' => $seller->id,
            'status' => OrderStatus::Completed,
            'subtotal' => 125,
            'shipping_fee' => 0,
            'discount' => 0,
            'total' => 125,
            'placed_at' => now(),
        ]);
        $parcel = Parcel::query()->create([
            'order_id' => $order->id,
            'tracking_number' => $orderNumber,
            'status' => OrderStatus::Completed,
        ]);
        DeliveryAssignment::query()->create([
            'parcel_id' => $parcel->id,
            'courier_id' => $rider->id,
            'status' => 'delivered',
            'delivered_at' => now(),
        ]);

        return $order;
    }

    private function createUserWithRole(string $role): User
    {
        $user = User::factory()->create(['status' => UserStatus::Active]);
        $user->assignRole($role);

        return $user;
    }
}
