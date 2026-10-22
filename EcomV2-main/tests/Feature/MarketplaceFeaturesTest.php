<?php

namespace Tests\Feature;

use App\Enums\OrderStatus;
use App\Enums\UserStatus;
use App\Models\Cart;
use App\Models\CartItem;
use App\Models\Category;
use App\Models\Conversation;
use App\Models\Order;
use App\Models\Product;
use App\Models\ProductVariant;
use App\Models\User;
use App\Models\Voucher;
use Database\Seeders\CatalogSeeder;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class MarketplaceFeaturesTest extends TestCase
{
    use RefreshDatabase;

    public function test_public_pages_no_longer_offer_a_hotline_or_sorting_center_signup(): void
    {
        $this->get('/')->assertOk()->assertDontSee('Hotline 24/7')->assertDontSee('Sorting Center')->assertDontSee('Sorting center');
        $this->get(route('register.logistics'))->assertRedirect(route('home'));
        $this->post(route('register.logistics'))->assertRedirect(route('home'));
    }

    public function test_logged_in_buyer_can_open_a_shop_using_the_same_delivery_address(): void
    {
        $this->seed(RoleSeeder::class);
        $this->seed(CatalogSeeder::class);
        $buyer = User::factory()->create(['status' => UserStatus::Active]);
        $buyer->assignRole('buyer');
        $buyer->addresses()->create([
            'label' => 'Home',
            'street_line' => '12 Mabini Street',
            'city_name' => 'Manila',
            'region_name' => 'National Capital Region',
            'postal_code' => '1000',
            'is_default' => true,
        ]);
        $category = Category::query()->where('is_active', true)->where('is_line_of_business', true)->firstOrFail();

        $this->actingAs($buyer)->get(route('register.seller'))
            ->assertOk()
            ->assertSee('Use the same address as my delivery address')
            ->assertDontSee('Pickup address');

        $this->actingAs($buyer)->post(route('register.seller'), [
            'business_name' => 'Mabini Crafts',
            'shop_category_id' => $category->id,
            'seller_type' => 'individual',
            'tin' => '123456789000',
            'use_same_address' => '1',
            'terms' => '1',
            'documents' => [
                'government_id' => UploadedFile::fake()->create('id.pdf', 100, 'application/pdf'),
            ],
        ])->assertRedirect(route('seller.dashboard'));

        $buyer->refresh();
        $this->assertTrue($buyer->hasRole('seller'));
        $this->assertSame('Manila', $buyer->sellerProfile->addresses()->firstOrFail()->city_name);
        $this->assertSame('12 Mabini Street', $buyer->sellerProfile->addresses()->firstOrFail()->street_line);
    }

    public function test_buyer_seller_and_rider_can_chat_on_an_order(): void
    {
        $this->seed(RoleSeeder::class);
        [$buyer, $seller, $order] = $this->makePlacedOrder();

        $this->actingAs($buyer)->post(route('chat.start'), ['order_id' => $order->id])
            ->assertRedirect();
        $conversation = Conversation::query()->where('order_id', $order->id)->firstOrFail();
        $this->actingAs($buyer)->post(route('chat.send', $conversation), ['message' => 'Is this still available tomorrow?'])
            ->assertRedirect();
        $this->actingAs($seller)->get(route('chat.show', $conversation))
            ->assertOk()
            ->assertSee('Is this still available tomorrow?');
        $this->actingAs($seller)->post(route('chat.send', $conversation), ['message' => 'Yes, I will pack it today.'])
            ->assertRedirect();
        $this->actingAs($buyer)->get(route('notifications.index'))
            ->assertOk()
            ->assertSee('Yes, I will pack it today.');
    }

    public function test_shop_voucher_reduces_checkout_merchandise_and_not_shipping(): void
    {
        $this->seed(RoleSeeder::class);
        [$buyer, $seller] = $this->makeCart();
        Voucher::query()->create([
            'code' => 'SHOP10',
            'type' => 'fixed',
            'value' => 4,
            'min_order' => 0,
            'seller_id' => $seller->id,
            'is_active' => true,
        ]);

        $this->actingAs($buyer)->post(route('checkout.place'), array_merge($this->checkoutData(), [
            'voucher_code' => 'SHOP10',
        ]))->assertRedirect(route('buyer.home'));

        $order = Order::query()->firstOrFail();
        $this->assertSame('4.00', $order->discount);
        $this->assertSame('50.00', $order->shipping_fee);
        $this->assertSame('58.00', $order->total);
        $this->assertDatabaseHas('voucher_usages', [
            'order_id' => $order->id,
            'buyer_id' => $buyer->id,
        ]);
    }

    public function test_profile_photo_is_stored_and_served_from_jeap(): void
    {
        $this->seed(RoleSeeder::class);
        Storage::fake('public');
        $buyer = User::factory()->create(['status' => UserStatus::Active]);
        $buyer->assignRole('buyer');

        $this->actingAs($buyer)->from(route('profile'))->post(route('profile.update'), [
            'first_name' => $buyer->first_name,
            'last_name' => $buyer->last_name,
            'email' => $buyer->email,
            'avatar' => UploadedFile::fake()->createWithContent(
                'me.png',
                base64_decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/n4sAAAAASUVORK5CYII=')
            ),
        ])->assertRedirect(route('profile'));

        $this->assertNotEmpty($buyer->fresh()->avatar_path);
        $this->actingAs($buyer)->get(route('media.avatar', $buyer))->assertOk();
    }

    public function test_account_password_and_notification_settings_can_be_updated(): void
    {
        $this->seed(RoleSeeder::class);
        $buyer = User::factory()->create(['status' => UserStatus::Active]);
        $buyer->assignRole('buyer');

        $this->actingAs($buyer)->get(route('account.password'))->assertOk()->assertSee('Change password');
        $this->actingAs($buyer)->post(route('account.password.update'), [
            'current_password' => 'password',
            'password' => 'NewPass#2026',
            'password_confirmation' => 'NewPass#2026',
        ])->assertRedirect(route('account.password'));

        $this->actingAs($buyer)->post(route('account.notification-settings.update'), [
            'order_updates' => '1',
            'chat' => '0',
        ])->assertRedirect();
        $this->assertFalse($buyer->fresh()->wantsNotification('chat'));
    }

    public function test_tracking_page_uses_shopper_delivery_steps(): void
    {
        $this->seed(RoleSeeder::class);
        [$buyer, , $order] = $this->makePlacedOrder();
        $this->actingAs($buyer)->get(route('buyer.orders.track', $order))
            ->assertOk()
            ->assertSee('Order placed')
            ->assertSee('Out for delivery')
            ->assertSee('Chat about this order');
    }

    private function makeCart(): array
    {
        $buyer = User::factory()->create(['status' => UserStatus::Active]);
        $buyer->assignRole('buyer');
        $seller = User::factory()->create(['status' => UserStatus::Active]);
        $seller->assignRole('seller');
        $category = Category::query()->create(['name' => 'Test', 'slug' => 'test-cat', 'is_active' => true]);
        $product = Product::query()->create([
            'seller_id' => $seller->id,
            'category_id' => $category->id,
            'name' => 'Test Product',
            'slug' => 'test-product-voucher',
            'status' => 'active',
        ]);
        $variant = ProductVariant::query()->create([
            'product_id' => $product->id,
            'sku' => 'TEST-V',
            'price' => 6,
            'stock' => 20,
            'is_active' => true,
        ]);
        $cart = Cart::query()->create(['user_id' => $buyer->id]);
        CartItem::query()->create([
            'cart_id' => $cart->id,
            'seller_id' => $seller->id,
            'product_variant_id' => $variant->id,
            'quantity' => 2,
            'unit_price' => 6,
        ]);

        return [$buyer, $seller];
    }

    private function makePlacedOrder(): array
    {
        [$buyer, $seller] = $this->makeCart();
        $order = Order::query()->create([
            'checkout_group_id' => 'group-1',
            'order_number' => 'JEAP-CHAT01',
            'buyer_id' => $buyer->id,
            'seller_id' => $seller->id,
            'status' => OrderStatus::Placed,
            'subtotal' => 12,
            'shipping_fee' => 50,
            'discount' => 0,
            'total' => 62,
            'placed_at' => now(),
        ]);

        return [$buyer, $seller, $order];
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
            'country' => 'Philippines',
            'country_code' => 'PH',
            'phone' => '09170000000',
            'email' => 'buyer@example.test',
            'gateway' => 'cod',
        ];
    }
}
