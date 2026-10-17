<?php

namespace Tests\Feature;

use App\Commerce\ShipmentWorkflow;
use App\Enums\OrderStatus;
use App\Enums\UserStatus;
use App\Models\Order;
use App\Models\Parcel;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Symfony\Component\HttpKernel\Exception\ConflictHttpException;
use Tests\TestCase;

class ShipmentWorkflowTest extends TestCase
{
    use RefreshDatabase;

    public function test_shipment_transition_updates_order_parcel_and_history_together(): void
    {
        $seller = User::factory()->create(['status' => UserStatus::Active]);
        $buyer = User::factory()->create(['status' => UserStatus::Active]);
        $rider = User::factory()->create(['status' => UserStatus::Active]);
        $order = Order::query()->create([
            'checkout_group_id' => fake()->uuid(),
            'order_number' => 'JEP-TEST-0001',
            'buyer_id' => $buyer->id,
            'seller_id' => $seller->id,
            'status' => OrderStatus::ReadyForPickup,
            'subtotal' => 100,
            'shipping_fee' => 0,
            'discount' => 0,
            'total' => 100,
            'placed_at' => now(),
        ]);
        $parcel = Parcel::query()->create([
            'order_id' => $order->id,
            'tracking_number' => 'JEPTEST0001',
            'status' => OrderStatus::ReadyForPickup,
        ]);

        app(ShipmentWorkflow::class)->transition(
            $order,
            $parcel,
            OrderStatus::PickedUp,
            $rider,
            'Collected from seller.',
        );

        $this->assertSame(OrderStatus::PickedUp, $order->fresh()->status);
        $this->assertSame(OrderStatus::PickedUp, $parcel->fresh()->status);
        $this->assertDatabaseHas('order_status_histories', [
            'order_id' => $order->id,
            'from_status' => OrderStatus::ReadyForPickup->value,
            'to_status' => OrderStatus::PickedUp->value,
            'actor_id' => $rider->id,
        ]);

        $this->expectException(ConflictHttpException::class);
        app(ShipmentWorkflow::class)->transition(
            $order->fresh(),
            $parcel->fresh(),
            OrderStatus::Delivered,
            $rider,
            'Invalid skipped stages.',
        );
    }
}
