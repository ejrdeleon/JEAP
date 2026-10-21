<?php

namespace Tests\Feature;

use App\Commerce\CommissionService;
use App\Enums\OrderStatus;
use App\Enums\UserStatus;
use App\Models\Cart;
use App\Models\CartItem;
use App\Models\Category;
use App\Models\Commission;
use App\Models\Order;
use App\Models\Product;
use App\Models\ProductVariant;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Tests\TestCase;

class CheckoutTest extends TestCase
{
    use RefreshDatabase;

    public function test_buyer_checkout_places_cod_order_and_reserves_stock(): void
    {
        $this->seed(RoleSeeder::class);
        [$buyer, $cart, $variant] = $this->makeCart();
        $this->actingAs($buyer)->get(route('checkout'))
            ->assertOk()
            ->assertSee('place order')
            ->assertSee('Cash on Delivery')
            ->assertSee('Standard shipping')
            ->assertDontSee('Worldwide Standard Shipping')
            ->assertDontSee('Direct Bank Transfer')
            ->assertDontSee('Paypal');

        $this->get(route('products.show', $variant->product->slug))
            ->assertOk()
            ->assertDontSee('buy with')
            ->assertDontSee('paypal.svg')
            ->assertSee('data-quantity-decrease', false)
            ->assertSee('data-quantity-increase', false)
            ->assertSee('data-existing-quantity="2"', false);

        $this->get(route('products.pay', $variant->product->slug))
            ->assertOk()
            ->assertSee('data-quantity-decrease', false)
            ->assertSee('data-quantity-increase', false)
            ->assertSee('data-existing-quantity="2"', false);

        $this->actingAs($buyer)->post(route('checkout.place'), $this->checkoutData())
            ->assertRedirect(route('buyer.home'))
            ->assertSessionHas('toast');

        $this->assertDatabaseCount('orders', 1);
        $order = Order::query()->firstOrFail();
        $this->assertSame(OrderStatus::Placed, $order->status);
        $this->assertSame('12.00', $order->subtotal);
        $this->assertSame('50.00', $order->shipping_fee);
        $this->assertSame('62.00', $order->total);
        $this->assertNotNull($order->shipping_address_id);
        $this->assertSame('1 Test Street', $order->shipping_address_snapshot['street_line']);
        $this->assertSame('1300000000', $order->shipping_address_snapshot['region_code']);
        $this->assertSame('Ermita', $order->shipping_address_snapshot['barangay_name']);
        $this->assertSame('PH', $order->shipping_address_snapshot['country_code']);
        $this->assertSame('Philippines', $order->shipping_address_snapshot['country_name']);
        $this->assertDatabaseHas('addresses', [
            'id' => $order->shipping_address_id,
            'addressable_id' => $buyer->id,
            'street_line' => '1 Test Street',
        ]);
        $this->assertSame(18, $variant->fresh()->stock);
        $this->assertDatabaseHas('payments', [
            'order_id' => $order->id,
            'method' => 'cod',
            'status' => 'pending',
        ]);
        $this->assertDatabaseHas('commissions', [
            'order_id' => $order->id,
            'seller_id' => $order->seller_id,
            'rate' => '20.00',
            'amount' => '2.40',
        ]);
        $commissionId = $order->commission()->value('id');
        app(CommissionService::class)->record($order);
        $this->assertSame($commissionId, $order->commission()->value('id'));
        $this->assertSame(1, Commission::query()->where('order_id', $order->id)->count());
        $this->assertDatabaseMissing('cart_items', ['cart_id' => $cart->id]);
    }

    public function test_checkout_persists_selected_pin_in_saved_address_and_order_snapshot(): void
    {
        $this->seed(RoleSeeder::class);
        [$buyer] = $this->makeCart();
        $address = $buyer->addresses()->create([
            'recipient_name' => 'Saved Buyer',
            'phone' => '09170000000',
            'street_line' => 'Map Pin Street',
            'city_name' => 'Quezon City',
            'latitude' => '14.6760000',
            'longitude' => '121.0437000',
        ]);

        $this->actingAs($buyer)->post(route('checkout.place'), array_merge(
            $this->checkoutData(),
            ['address_id' => $address->id]
        ))->assertRedirect(route('buyer.home'));

        $order = Order::query()->firstOrFail();
        $this->assertSame($address->id, $order->shipping_address_id);
        $this->assertSame('14.6760000', $order->shipping_address_snapshot['latitude']);
        $this->assertSame('121.0437000', $order->shipping_address_snapshot['longitude']);
        $this->assertSame('Map Pin Street', $order->shipping_address_snapshot['street_line']);
    }

    public function test_checkout_rejects_an_address_owned_by_another_buyer(): void
    {
        $this->seed(RoleSeeder::class);
        [$buyer] = $this->makeCart();
        $otherBuyer = User::factory()->create(['status' => UserStatus::Active]);
        $otherBuyer->assignRole('buyer');
        $address = $otherBuyer->addresses()->create([
            'recipient_name' => 'Another Buyer',
            'phone' => '09170000000',
            'street_line' => 'Private Street',
            'city_name' => 'Manila',
        ]);

        $this->actingAs($buyer)->from(route('checkout'))->post(route('checkout.place'), array_merge(
            $this->checkoutData(),
            ['address_id' => $address->id]
        ))->assertRedirect(route('checkout'))
            ->assertSessionHasErrors('address_id');

        $this->assertDatabaseCount('orders', 0);
    }

    public function test_checkout_rejects_out_of_range_pin_coordinates(): void
    {
        $this->seed(RoleSeeder::class);
        [$buyer] = $this->makeCart();

        $this->actingAs($buyer)->from(route('checkout'))->post(route('checkout.place'), array_merge(
            $this->checkoutData(),
            ['latitude' => '91', 'longitude' => '121']
        ))->assertRedirect(route('checkout'))
            ->assertSessionHasErrors('latitude');

        $this->assertDatabaseCount('orders', 0);
    }

    public function test_checkout_rejects_insufficient_stock_without_creating_an_order(): void
    {
        $this->seed(RoleSeeder::class);
        [$buyer, $cart, $variant] = $this->makeCart(1);

        $this->actingAs($buyer)->from(route('checkout'))->post(route('checkout.place'), $this->checkoutData())
            ->assertRedirect(route('checkout'))
            ->assertSessionHasErrors('cart');

        $this->assertDatabaseCount('orders', 0);
        $this->assertSame(1, $variant->fresh()->stock);
        $this->assertDatabaseHas('cart_items', ['cart_id' => $cart->id]);
    }

    public function test_guest_cannot_access_checkout(): void
    {
        $this->get(route('cart.index'))->assertOk();
        $this->get(route('checkout'))->assertRedirect(route('login'));
    }

    public function test_buyer_navigation_opens_the_live_catalog_cart_and_cod_checkout(): void
    {
        $this->seed(RoleSeeder::class);
        [$buyer] = $this->makeCart();

        $this->actingAs($buyer)->get(route('search', ['q' => 'Test']))
            ->assertRedirect(route('products.index', ['q' => 'Test']));
        $this->actingAs($buyer)->get(route('buyer.cart'))->assertRedirect(route('cart.index'));
        $this->actingAs($buyer)->get(route('buyer.checkout'))->assertRedirect(route('checkout'));

        $this->get(route('products.index', ['q' => 'Test', 'min_price' => 7]))
            ->assertOk()->assertSee('No products found.');
        $this->get(route('products.index', ['q' => 'Test', 'min_price' => 5, 'max_price' => 7, 'sort' => 'price_asc', 'in_stock' => 1]))
            ->assertOk()->assertSee('Test Product');
        $this->get(route('products.index', ['min_price' => 10, 'max_price' => 5]))
            ->assertSessionHasErrors('max_price');
    }

    public function test_buyer_dashboard_shows_only_the_signed_in_buyers_orders(): void
    {
        $this->seed(RoleSeeder::class);
        [$buyer] = $this->makeCart();
        $otherBuyer = User::factory()->create(['status' => UserStatus::Active]);
        $otherBuyer->assignRole('buyer');

        $this->actingAs($buyer)->post(route('checkout.place'), $this->checkoutData())
            ->assertRedirect(route('buyer.home'));

        $ownOrder = Order::query()->where('buyer_id', $buyer->id)->firstOrFail();
        $otherSeller = User::factory()->create(['status' => UserStatus::Active]);
        $otherOrder = Order::query()->create([
            'checkout_group_id' => (string) Str::uuid(),
            'order_number' => 'PRIVATE-ORDER-123',
            'buyer_id' => $otherBuyer->id,
            'seller_id' => $otherSeller->id,
            'status' => OrderStatus::Placed,
            'subtotal' => 12,
            'shipping_fee' => 0,
            'discount' => 0,
            'total' => 12,
            'placed_at' => now(),
        ]);

        $this->actingAs($buyer)->get(route('buyer.home'))
            ->assertOk()
            ->assertSee('Recent orders')
            ->assertSee($ownOrder->order_number)
            ->assertDontSee($otherOrder->order_number)
            ->assertSee(route('buyer.orders.track', $ownOrder));
    }

    public function test_cart_explains_insufficient_stock_and_blocks_checkout(): void
    {
        $this->seed(RoleSeeder::class);
        [$buyer] = $this->makeCart(1);

        $this->actingAs($buyer)->get(route('cart.index'))
            ->assertOk()
            ->assertSee('Test Product')
            ->assertSee('at least 10 units in stock')
            ->assertSee('Update or remove unavailable items to continue.')
            ->assertSee('aria-label="Decrease quantity"', false)
            ->assertSee('aria-label="Increase quantity"', false)
            ->assertSee('data-cart-update-form', false)
            ->assertSee('disabled', false)
            ->assertDontSee('Shipping estimate:')
            ->assertDontSee('Tax estimate:');
    }

    public function test_profile_form_updates_account_fields_with_labeled_inputs(): void
    {
        $this->seed(RoleSeeder::class);
        [$buyer] = $this->makeCart();

        $this->actingAs($buyer)->get(route('profile'))
            ->assertOk()
            ->assertSee('Account information')
            ->assertSee('for="profile-first-name"', false)
            ->assertSee('for="profile-email"', false)
            ->assertDontSee('Change password');

        $this->actingAs($buyer)->from(route('profile'))->post(route('profile.update'), [
            'first_name' => 'Updated',
            'last_name' => 'Buyer',
            'email' => $buyer->email,
            'phone' => '09171112222',
        ])->assertRedirect(route('profile'))
            ->assertSessionHas('toast', 'Account info saved');

        $this->assertDatabaseHas('users', [
            'id' => $buyer->id,
            'first_name' => 'Updated',
            'phone' => '09171112222',
        ]);
    }

    public function test_api_checkout_rejects_unsupported_payment_methods(): void
    {
        $this->seed(RoleSeeder::class);
        [$buyer] = $this->makeCart();
        $address = $buyer->addresses()->create([
            'street_line' => '1 Test Street',
            'city_name' => 'Manila',
        ]);

        $this->actingAs($buyer, 'sanctum')->postJson('/api/v1/orders', [
            'address_id' => $address->id,
            'payment_method' => 'paypal',
        ])->assertUnprocessable()->assertJsonValidationErrors('payment_method');
    }

    public function test_api_checkout_reserves_stock_and_creates_cod_payment(): void
    {
        $this->seed(RoleSeeder::class);
        [$buyer, $cart, $variant] = $this->makeCart();
        $address = $buyer->addresses()->create([
            'street_line' => '1 Test Street',
            'city_name' => 'Manila',
        ]);

        $this->actingAs($buyer, 'sanctum')->postJson('/api/v1/orders', [
            'address_id' => $address->id,
            'payment_method' => 'cod',
        ])->assertCreated()->assertJsonPath('message', 'Order placed successfully.');

        $this->assertDatabaseCount('orders', 1);
        $order = Order::query()->firstOrFail();
        $this->assertSame(18, $variant->fresh()->stock);
        $this->assertDatabaseHas('payments', [
            'order_id' => $order->id,
            'method' => 'cod',
            'status' => 'pending',
        ]);
        $this->assertDatabaseHas('commissions', [
            'order_id' => $order->id,
            'seller_id' => $order->seller_id,
            'rate' => '20.00',
            'amount' => '2.40',
        ]);
        $this->assertDatabaseMissing('cart_items', ['cart_id' => $cart->id]);
    }

    public function test_buyer_can_rate_a_product_from_a_completed_order(): void
    {
        $this->seed(RoleSeeder::class);
        [$buyer, , $variant] = $this->makeCart();
        $sellerId = $variant->product->seller_id;
        $order = Order::query()->create([
            'checkout_group_id' => Str::uuid()->toString(),
            'order_number' => 'JEAP-TEST1234',
            'buyer_id' => $buyer->id,
            'seller_id' => $sellerId,
            'status' => OrderStatus::Completed,
            'subtotal' => 12,
            'shipping_fee' => 0,
            'discount' => 0,
            'total' => 12,
            'placed_at' => now(),
        ]);
        $order->items()->create([
            'product_id' => $variant->product_id,
            'product_variant_id' => $variant->id,
            'name' => 'Test Product',
            'sku' => $variant->sku,
            'quantity' => 1,
            'unit_price' => 12,
            'subtotal' => 12,
        ]);

        $this->actingAs($buyer, 'sanctum')->postJson('/api/v1/orders/'.$order->order_number.'/rate', [
            'product_id' => $variant->product_id,
            'rating' => 5,
            'review' => 'Works well.',
        ])->assertOk();

        $this->assertDatabaseHas('reviews', [
            'order_id' => $order->id,
            'buyer_id' => $buyer->id,
            'product_id' => $variant->product_id,
            'rating' => 5,
            'comment' => 'Works well.',
        ]);
    }

    public function test_buyer_can_cancel_an_unshipped_order_with_a_reason_and_stock_is_restored(): void
    {
        $this->seed(RoleSeeder::class);
        [$buyer, , $variant] = $this->makeCart();
        $this->actingAs($buyer)->post(route('checkout.place'), $this->checkoutData())->assertRedirect(route('buyer.home'));
        $order = Order::query()->firstOrFail();
        $this->assertSame(18, $variant->fresh()->stock);

        $this->actingAs($buyer)->from(route('buyer.home'))->post(route('buyer.orders.cancel', $order), ['reason' => 'Changed'])
            ->assertRedirect(route('buyer.home'))->assertSessionHasErrors('reason');
        $this->assertSame(OrderStatus::Placed, $order->fresh()->status);

        $this->actingAs($buyer)->from(route('buyer.home'))->post(route('buyer.orders.cancel', $order), ['reason' => 'Ordered by mistake'])
            ->assertRedirect(route('buyer.home'))->assertSessionHas('status', 'Your order was cancelled.');

        $this->assertSame(OrderStatus::Cancelled, $order->fresh()->status);
        $this->assertSame('Ordered by mistake', $order->fresh()->cancellation_reason);
        $this->assertSame(20, $variant->fresh()->stock);
        $this->assertDatabaseHas('payments', ['order_id' => $order->id, 'status' => 'cancelled']);
        $this->assertDatabaseHas('order_status_histories', [
            'order_id' => $order->id,
            'from_status' => OrderStatus::Placed->value,
            'to_status' => OrderStatus::Cancelled->value,
        ]);
    }

    private function makeCart(int $stock = 20): array
    {
        $buyer = User::factory()->create(['status' => UserStatus::Active]);
        $buyer->assignRole('buyer');
        $seller = User::factory()->create(['status' => UserStatus::Active]);
        $seller->assignRole('seller');

        $category = Category::query()->create([
            'name' => 'Test Category', 'slug' => 'test-category', 'is_active' => true,
        ]);
        $product = Product::query()->create([
            'seller_id' => $seller->id,
            'category_id' => $category->id,
            'name' => 'Test Product',
            'slug' => 'test-product',
            'status' => 'active',
        ]);
        $variant = ProductVariant::query()->create([
            'product_id' => $product->id,
            'sku' => 'TEST-001',
            'price' => 6,
            'stock' => $stock,
            'is_active' => true,
        ]);
        $cart = Cart::query()->create(['user_id' => $buyer->id]);
        CartItem::query()->create([
            'cart_id' => $cart->id,
            'seller_id' => $seller->id,
            'product_variant_id' => $variant->id,
            'quantity' => 2,
            'unit_price' => 5,
        ]);

        return [$buyer, $cart, $variant];
    }

    private function checkoutData(): array
    {
        return [
            'first_name' => 'Test',
            'last_name' => 'Buyer',
            'street' => '1 Test Street',
            'city' => 'Manila',
            'province' => 'Metro Manila',
            'region_name' => 'National Capital Region',
            'barangay' => 'Ermita',
            'region_code' => '1300000000',
            'province_code' => '',
            'city_code' => '1380600000',
            'barangay_code' => '1380600010',
            'country' => 'Philippines',
            'country_code' => 'PH',
            'phone' => '09170000000',
            'email' => 'buyer@example.test',
            'gateway' => 'cod',
        ];
    }
}
