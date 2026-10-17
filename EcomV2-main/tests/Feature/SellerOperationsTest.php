<?php

namespace Tests\Feature;

use App\Enums\OrderStatus;
use App\Enums\PaymentStatus;
use App\Enums\UserStatus;
use App\Models\Category;
use App\Models\Commission;
use App\Models\Order;
use App\Models\Payment;
use App\Models\Product;
use App\Models\ProductVariant;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Tests\TestCase;

class SellerOperationsTest extends TestCase
{
    use RefreshDatabase;

    public function test_seller_can_create_edit_and_archive_a_product_and_store_an_image(): void
    {
        $this->seed(RoleSeeder::class);
        Storage::fake('public');
        [$seller, $category] = $this->makeSellerAndCategory();

        $this->actingAs($seller)->post(route('seller.catalog.store'), [
            'name' => 'Wireless Headphones',
            'category_id' => $category->id,
            'description' => 'A test listing.',
            'price' => '30.00',
            'compare_at_price' => '39.00',
            'stock' => 8,
            'status' => 'draft',
            'image' => UploadedFile::fake()->createWithContent(
                'headphones.png',
                base64_decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/n4sAAAAASUVORK5CYII=')
            ),
        ])->assertRedirect(route('seller.catalog'));

        $product = Product::query()->where('seller_id', $seller->id)->firstOrFail();
        $variant = $product->variants()->firstOrFail();
        $image = $product->images()->firstOrFail();

        $this->assertSame('draft', $product->status);
        $this->assertSame('wireless-headphones', $product->slug);
        $this->assertSame('8', (string) $variant->stock);
        Storage::disk('public')->assertExists(Str::after($image->path, 'storage/'));

        $this->actingAs($seller)->put(route('seller.catalog.update', $product), [
            'name' => 'Wireless Headphones Pro',
            'category_id' => $category->id,
            'description' => 'Updated listing.',
            'price' => '35.00',
            'compare_at_price' => '45.00',
            'stock' => 5,
            'status' => 'active',
        ])->assertRedirect(route('seller.catalog'));

        $this->assertSame('active', $product->fresh()->status);
        $this->assertSame('wireless-headphones-pro', $product->fresh()->slug);
        $this->assertSame('35.00', $variant->fresh()->price);
        $this->assertSame(5, $variant->fresh()->stock);

        $this->actingAs($seller)->delete(route('seller.catalog.archive', $product))
            ->assertRedirect(route('seller.catalog'));

        $this->assertSame('inactive', $product->fresh()->status);
        $this->assertFalse($variant->fresh()->is_active);
    }

    public function test_seller_cannot_manage_another_sellers_product_and_unsupported_images_are_rejected(): void
    {
        $this->seed(RoleSeeder::class);
        [$seller, $category] = $this->makeSellerAndCategory();
        $otherSeller = User::factory()->create(['status' => UserStatus::Active]);
        $otherSeller->assignRole('seller');
        $product = Product::query()->create([
            'seller_id' => $otherSeller->id,
            'category_id' => $category->id,
            'name' => 'Private listing',
            'slug' => 'private-listing',
            'status' => 'active',
        ]);

        $this->actingAs($seller)->get(route('seller.catalog.edit', $product))->assertNotFound();
        $this->actingAs($seller)->delete(route('seller.catalog.archive', $product))->assertNotFound();

        Storage::fake('public');
        $this->actingAs($seller)->from(route('seller.catalog'))->post(route('seller.catalog.store'), [
            'name' => 'Unsupported image listing',
            'category_id' => $category->id,
            'price' => '10.00',
            'stock' => 1,
            'status' => 'active',
            'image' => UploadedFile::fake()->createWithContent('vector.svg', '<svg xmlns="http://www.w3.org/2000/svg"></svg>'),
        ])->assertRedirect(route('seller.catalog'))->assertSessionHasErrors('image');

        $this->assertDatabaseMissing('products', ['name' => 'Unsupported image listing']);
    }

    public function test_seller_order_cancellation_restores_stock_once_and_voids_payment_and_commission(): void
    {
        $this->seed(RoleSeeder::class);
        [$seller, , $order, $variant] = $this->makeSellerOrder();
        $otherSeller = User::factory()->create(['status' => UserStatus::Active]);
        $otherSeller->assignRole('seller');

        $this->actingAs($otherSeller)->patch(route('seller.orders.status', $order), ['status' => OrderStatus::Cancelled->value])
            ->assertNotFound();

        $this->actingAs($seller)->patch(route('seller.orders.status', $order), ['status' => OrderStatus::Cancelled->value])
            ->assertRedirect();

        $this->assertSame(5, $variant->fresh()->stock);
        $this->assertSame(OrderStatus::Cancelled, $order->fresh()->status);
        $this->assertSame(PaymentStatus::Cancelled, $order->payments()->value('status'));
        $this->assertSame('void', $order->commission()->value('status'));
        $this->assertDatabaseCount('order_status_histories', 1);

        $this->actingAs($seller)->patch(route('seller.orders.status', $order), ['status' => OrderStatus::Cancelled->value])
            ->assertStatus(409);

        $this->assertSame(5, $variant->fresh()->stock);
        $this->assertDatabaseCount('order_status_histories', 1);
    }

    public function test_seller_order_follows_only_the_allowed_pre_pickup_transitions(): void
    {
        $this->seed(RoleSeeder::class);
        [$seller, , $order] = $this->makeSellerOrder();
        $this->actingAs($seller);

        $this->patch(route('seller.orders.status', $order), ['status' => OrderStatus::Preparing->value])->assertStatus(409);
        $this->patch(route('seller.orders.status', $order), ['status' => OrderStatus::Confirmed->value])->assertRedirect();
        $this->patch(route('seller.orders.status', $order), ['status' => OrderStatus::Preparing->value])->assertRedirect();
        $this->patch(route('seller.orders.status', $order), ['status' => OrderStatus::ReadyForPickup->value])->assertRedirect();
        $this->patch(route('seller.orders.status', $order), ['status' => OrderStatus::Cancelled->value])->assertStatus(409);

        $this->assertSame(OrderStatus::ReadyForPickup, $order->fresh()->status);
        $this->assertDatabaseCount('order_status_histories', 3);
    }

    public function test_seller_dashboard_metrics_are_scoped_to_the_signed_in_seller(): void
    {
        $this->seed(RoleSeeder::class);
        [$seller, , $order] = $this->makeSellerOrder();
        $category = Category::query()->where('slug', 'seller-test-category')->firstOrFail();
        $otherSeller = User::factory()->create(['status' => UserStatus::Active]);
        $otherSeller->assignRole('seller');
        $otherProduct = Product::query()->create([
            'seller_id' => $otherSeller->id,
            'category_id' => $category->id,
            'name' => 'Other seller product',
            'slug' => 'other-seller-product',
            'status' => 'active',
        ]);
        $otherProduct->variants()->create([
            'sku' => 'OTHER-SELLER-1',
            'price' => 10,
            'stock' => 1,
            'is_active' => true,
        ]);

        $response = $this->actingAs($seller)->get(route('seller.dashboard'))->assertOk();
        $response->assertViewHas('productCount', 1);
        $response->assertViewHas('lowStockCount', 1);
        $response->assertViewHas('openOrderCount', 1);
        $response->assertViewHas('recentOrders', fn ($orders) => $orders->contains('id', $order->id));
    }

    public function test_seller_order_view_uses_the_persisted_commission_for_payout(): void
    {
        $this->seed(RoleSeeder::class);
        [$seller, , $order] = $this->makeSellerOrder();

        $this->actingAs($seller)->get(route('seller.orders'))
            ->assertOk()
            ->assertSee('₱4.00')
            ->assertSee('₱36.00');
    }

    private function makeSellerAndCategory(): array
    {
        $seller = User::factory()->create(['status' => UserStatus::Active]);
        $seller->assignRole('seller');
        $category = Category::query()->create([
            'name' => 'Seller test category',
            'slug' => 'seller-test-category',
            'is_active' => true,
        ]);

        return [$seller, $category];
    }

    private function makeSellerOrder(): array
    {
        [$seller, $category] = $this->makeSellerAndCategory();
        $buyer = User::factory()->create(['status' => UserStatus::Active]);
        $buyer->assignRole('buyer');
        $product = Product::query()->create([
            'seller_id' => $seller->id,
            'category_id' => $category->id,
            'name' => 'Order test product',
            'slug' => 'order-test-product',
            'status' => 'active',
        ]);
        $variant = $product->variants()->create([
            'sku' => 'ORDER-TEST-1',
            'price' => 20,
            'stock' => 3,
            'is_active' => true,
        ]);
        $order = Order::query()->create([
            'checkout_group_id' => (string) Str::uuid(),
            'order_number' => 'JEAP-ORDERTEST',
            'buyer_id' => $buyer->id,
            'seller_id' => $seller->id,
            'status' => OrderStatus::Placed,
            'subtotal' => 40,
            'shipping_fee' => 0,
            'discount' => 0,
            'total' => 40,
            'placed_at' => now(),
        ]);
        $order->items()->create([
            'product_id' => $product->id,
            'product_variant_id' => $variant->id,
            'name' => $product->name,
            'sku' => $variant->sku,
            'quantity' => 2,
            'unit_price' => 20,
            'subtotal' => 40,
        ]);
        Payment::query()->create([
            'checkout_group_id' => $order->checkout_group_id,
            'order_id' => $order->id,
            'gateway' => 'cod',
            'method' => 'cod',
            'amount' => 40,
            'status' => 'pending',
        ]);
        Commission::query()->create([
            'order_id' => $order->id,
            'seller_id' => $seller->id,
            'rate' => 10,
            'amount' => 4,
            'status' => 'pending',
        ]);

        return [$seller, $buyer, $order, $variant];
    }
}
