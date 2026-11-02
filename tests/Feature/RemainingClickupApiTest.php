<?php

namespace Tests\Feature;

use App\Commerce\CommissionService;
use App\Enums\OrderStatus;
use App\Enums\UserStatus;
use App\Models\Cart;
use App\Models\Category;
use App\Models\Order;
use App\Models\Parcel;
use App\Models\PickupAssignment;
use App\Models\Product;
use App\Models\ProductVariant;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class RemainingClickupApiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
    }

    public function test_product_search_filter_api_and_slug_show(): void
    {
        [$purifier] = $this->makeListedProduct('Air Purifier with HEPA Filter', 'air-purifier-hepa', 489, 80, 'kitchen');
        $this->makeListedProduct('Office Chair', 'office-chair', 1200, 15, 'office');

        $this->getJson('/api/v1/products?q=Air+Purifier')
            ->assertOk()
            ->assertJsonPath('data.0.name', 'Air Purifier with HEPA Filter')
            ->assertJsonMissing(['name' => 'Office Chair']);

        $this->getJson('/api/v1/products?category=kitchen&max_price=500')
            ->assertOk()
            ->assertJsonPath('data.0.slug', 'air-purifier-hepa');

        $this->getJson('/api/v1/products/air-purifier-hepa')
            ->assertOk()
            ->assertJsonPath('product.id', $purifier->id);
    }

    public function test_cart_add_update_and_remove_api(): void
    {
        $buyer = $this->userWithRole('buyer');
        [, $variant] = $this->makeListedProduct('Cart Item', 'cart-item', 50, 20, 'kitchen');

        $this->actingAs($buyer, 'sanctum')->postJson('/api/v1/cart', [
            'product_variant_id' => $variant->id,
            'quantity' => 2,
        ])->assertOk();

        $cart = Cart::query()->where('user_id', $buyer->id)->firstOrFail();
        $itemId = $cart->items()->value('id');

        $this->actingAs($buyer, 'sanctum')->putJson('/api/v1/cart/'.$itemId, ['quantity' => 3])
            ->assertOk();
        $this->assertSame(3, (int) $cart->items()->value('quantity'));

        $this->actingAs($buyer, 'sanctum')->postJson('/api/v1/cart', [
            'product_variant_id' => $variant->id,
            'quantity' => 10,
        ])->assertStatus(422);

        $this->actingAs($buyer, 'sanctum')->deleteJson('/api/v1/cart/'.$itemId)->assertOk();
        $this->assertSame(0, $cart->items()->count());
    }

    public function test_admin_can_suspend_a_user_through_the_api_and_buyers_cannot(): void
    {
        $admin = $this->userWithRole('admin');
        $buyer = $this->userWithRole('buyer');

        $this->actingAs($buyer, 'sanctum')->patchJson('/api/v1/admin/users/'.$buyer->id.'/status', [
            'status' => UserStatus::Suspended->value,
            'reason' => 'Buyer trying to ban themselves',
        ])->assertForbidden();

        $this->actingAs($admin, 'sanctum')->patchJson('/api/v1/admin/users/'.$buyer->id.'/status', [
            'status' => UserStatus::Suspended->value,
            'reason' => 'Repeated checkout abuse reports',
        ])->assertOk()->assertJsonPath('user.status', UserStatus::Suspended->value);

        $this->assertSame(UserStatus::Suspended, $buyer->fresh()->status);
    }

    public function test_logistics_can_assign_a_courier_through_the_api(): void
    {
        $hub = $this->userWithRole('logistics');
        $courier = $this->userWithRole('courier');
        $seller = $this->userWithRole('seller');
        $buyer = $this->userWithRole('buyer');
        $order = Order::query()->create([
            'checkout_group_id' => fake()->uuid(),
            'order_number' => 'JEP-ASSIGN-1',
            'buyer_id' => $buyer->id,
            'seller_id' => $seller->id,
            'status' => OrderStatus::ReadyForPickup,
            'subtotal' => 100,
            'shipping_fee' => 50,
            'discount' => 0,
            'total' => 150,
            'placed_at' => now(),
        ]);
        $parcel = Parcel::query()->create([
            'order_id' => $order->id,
            'tracking_number' => 'JEPASSIGN001',
            'status' => OrderStatus::ReadyForPickup,
        ]);
        PickupAssignment::query()->create([
            'parcel_id' => $parcel->id,
            'seller_id' => $seller->id,
            'status' => 'pending',
        ]);

        $this->actingAs($hub, 'sanctum')->postJson('/api/v1/logistics/parcels/'.$parcel->id.'/pickup-assignment', [
            'courier_id' => $courier->id,
        ])->assertOk()->assertJsonPath('assignment.courier_id', $courier->id);

        $this->assertDatabaseHas('pickup_assignments', [
            'parcel_id' => $parcel->id,
            'courier_id' => $courier->id,
            'status' => 'pending',
        ]);
    }

    public function test_google_auth_route_rejects_unverified_tokens(): void
    {
        $this->postJson('/api/v1/auth/google', [])->assertStatus(401);
    }

    public function test_admin_can_change_the_commission_rate_and_new_orders_use_it(): void
    {
        $admin = $this->userWithRole('admin');
        $this->actingAs($admin)->put(route('admin.commission-rate.update'), [
            'commission_rate' => 25,
        ])->assertRedirect();

        $this->assertSame(25.0, CommissionService::rate());
        $this->assertSame(3.00, CommissionService::amountForSubtotal(12.00));
    }

    private function userWithRole(string $role): User
    {
        $user = User::factory()->create(['status' => UserStatus::Active]);
        $user->assignRole($role);

        return $user;
    }

    private function makeListedProduct(string $name, string $slug, float $price, int $stock, string $categorySlug): array
    {
        $seller = $this->userWithRole('seller');
        $category = Category::query()->firstOrCreate(
            ['slug' => $categorySlug],
            ['name' => ucfirst($categorySlug), 'is_active' => true]
        );
        $product = Product::query()->create([
            'seller_id' => $seller->id,
            'category_id' => $category->id,
            'name' => $name,
            'slug' => $slug,
            'status' => 'active',
        ]);
        $variant = ProductVariant::query()->create([
            'product_id' => $product->id,
            'sku' => strtoupper($slug).'-1',
            'price' => $price,
            'stock' => $stock,
            'is_active' => true,
        ]);

        return [$product, $variant];
    }
}
