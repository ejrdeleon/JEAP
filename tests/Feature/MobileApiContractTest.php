<?php

namespace Tests\Feature;

use App\Enums\OrderStatus;
use App\Enums\UserStatus;
use App\Enums\VehicleType;
use App\Models\Category;
use App\Models\Commission;
use App\Models\CourierProfile;
use App\Models\LogisticsProfile;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Parcel;
use App\Models\Product;
use App\Models\ProductVariant;
use App\Models\SellerProfile;
use App\Models\User;
use App\Models\Voucher;
use App\Notifications\EmailVerificationCodeNotification;
use App\Notifications\OrderPlacedNotification;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Notification;
use Illuminate\Support\Facades\Password;
use Tests\TestCase;

class MobileApiContractTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
    }

    public function test_mobile_register_verifies_email_and_issues_a_token(): void
    {
        Notification::fake();

        $this->postJson('/api/v1/register', [
            'first_name' => 'Mobile',
            'last_name' => 'Buyer',
            'email' => 'mobile.buyer@example.test',
            'password' => 'JeapBuyer@2026',
            'password_confirmation' => 'JeapBuyer@2026',
        ])->assertCreated()
            ->assertJsonPath('status', UserStatus::Unverified->value);

        $user = User::query()->where('email', 'mobile.buyer@example.test')->firstOrFail();
        $this->assertTrue($user->hasRole('buyer'));
        Notification::assertSentTo($user, EmailVerificationCodeNotification::class);
        $code = Notification::sent($user, EmailVerificationCodeNotification::class)->first()->code;

        $this->postJson('/api/v1/email/verify', [
            'email' => 'mobile.buyer@example.test',
            'code' => $code,
        ])->assertOk()
            ->assertJsonPath('user.email', 'mobile.buyer@example.test')
            ->assertJsonStructure(['token', 'user']);

        $this->assertSame(UserStatus::Active, $user->fresh()->status);
    }

    public function test_password_reset_api_updates_the_account(): void
    {
        $user = $this->userWithRole('buyer');

        $this->postJson('/api/v1/forgot-password', ['email' => $user->email])
            ->assertOk()
            ->assertJsonPath('message', 'If that email is registered with JEAP, we sent a reset link.');

        $token = Password::broker()->createToken($user);
        $this->postJson('/api/v1/reset-password', [
            'email' => $user->email,
            'token' => $token,
            'password' => 'JeapReset@2026',
            'password_confirmation' => 'JeapReset@2026',
        ])->assertOk();

        $this->assertTrue(Hash::check('JeapReset@2026', $user->fresh()->password));
    }

    public function test_google_auth_rejects_unverified_client_email_fallback(): void
    {
        Http::fake([
            'https://oauth2.googleapis.com/tokeninfo*' => Http::response(['error' => 'invalid_token'], 400),
        ]);

        $this->postJson('/api/v1/auth/google', [
            'id_token' => 'not-a-real-token',
            'email' => 'victim@example.test',
        ])->assertStatus(401);

        $this->assertDatabaseMissing('users', ['email' => 'victim@example.test']);
    }

    public function test_google_auth_uses_verified_token_email_not_client_email(): void
    {
        Http::fake([
            'https://oauth2.googleapis.com/tokeninfo*' => Http::response([
                'email' => 'google.mobile@example.test',
                'email_verified' => 'true',
                'aud' => config('services.google.client_id'),
                'given_name' => 'Google',
                'family_name' => 'Buyer',
            ]),
        ]);

        $this->postJson('/api/v1/auth/google', [
            'id_token' => 'real-looking-token',
            'email' => 'attacker@example.test',
        ])->assertOk()
            ->assertJsonPath('user.email', 'google.mobile@example.test')
            ->assertJsonStructure(['token', 'user']);

        $this->assertDatabaseMissing('users', ['email' => 'attacker@example.test']);
    }

    public function test_admin_cannot_issue_a_mobile_token(): void
    {
        $admin = $this->userWithRole('admin');

        $this->postJson('/api/v1/login', [
            'email' => $admin->email,
            'password' => 'password',
        ])->assertForbidden()
            ->assertJsonPath('message', 'Use the JEAP website to access this account.');
    }

    public function test_catalog_search_alias_show_by_id_home_and_seller_products(): void
    {
        [$product] = $this->makeListedProduct('Air Purifier with HEPA Filter', 'air-purifier-hepa', 489, 80, 'kitchen');
        $draft = Product::query()->create([
            'seller_id' => $product->seller_id,
            'category_id' => $product->category_id,
            'name' => 'Hidden Draft Fan',
            'slug' => 'hidden-draft-fan',
            'status' => 'draft',
        ]);

        $this->getJson('/api/v1/products?search=Air+Purifier')
            ->assertOk()
            ->assertJsonPath('data.0.name', 'Air Purifier with HEPA Filter');

        $this->getJson('/api/v1/products/'.$product->id)
            ->assertOk()
            ->assertJsonPath('product.slug', 'air-purifier-hepa');

        $this->getJson('/api/v1/products/air-purifier-hepa')
            ->assertOk()
            ->assertJsonPath('product.id', $product->id);

        $this->getJson('/api/v1/home')->assertOk()->assertJsonStructure(['featured', 'new_arrivals', 'categories']);
        $this->getJson('/api/v1/brands')->assertOk()->assertJsonPath('data.0.name', 'Test Shop');

        $seller = $product->seller;
        $this->actingAs($seller, 'sanctum')->getJson('/api/v1/seller/products')
            ->assertOk()
            ->assertJsonFragment(['slug' => 'hidden-draft-fan'])
            ->assertJsonFragment(['slug' => 'air-purifier-hepa']);

        $this->getJson('/api/v1/products')->assertOk()->assertJsonMissing(['slug' => 'hidden-draft-fan']);
        $this->assertSame('draft', $draft->fresh()->status);
    }

    public function test_buyer_can_cancel_and_seller_can_advance_order_status(): void
    {
        [$buyer, $seller, $order, $variant] = $this->makePlacedOrder();

        $this->actingAs($seller, 'sanctum')->postJson('/api/v1/seller/orders/'.$order->order_number.'/status', [
            'status' => OrderStatus::Confirmed->value,
        ])->assertOk()->assertJsonPath('order.status', OrderStatus::Confirmed->value);

        $this->actingAs($buyer, 'sanctum')->postJson('/api/v1/orders/'.$order->order_number.'/cancel', [
            'reason' => 'Changed my mind about this order.',
        ])->assertOk();

        $this->assertSame(OrderStatus::Cancelled, $order->fresh()->status);
        $this->assertSame(20, $variant->fresh()->stock);
        $this->assertSame('void', $order->commission()->value('status'));
    }

    public function test_notifications_conversations_vouchers_and_returns(): void
    {
        [$buyer, $seller, $order] = $this->makePlacedOrder();
        $seller->notify(new OrderPlacedNotification($order));
        Voucher::query()->create([
            'code' => 'SAVE10',
            'type' => 'percent',
            'value' => 10,
            'min_order' => 0,
            'seller_id' => $seller->id,
            'is_active' => true,
        ]);

        $this->actingAs($seller, 'sanctum')->getJson('/api/v1/notifications')
            ->assertOk()
            ->assertJsonPath('unread_count', 1);

        $this->actingAs($buyer, 'sanctum')->putJson('/api/v1/notification-preferences', [
            'order_updates' => true,
            'chat' => false,
            'promos' => false,
        ])->assertOk()->assertJsonPath('preferences.chat', false);

        $this->actingAs($buyer, 'sanctum')->getJson('/api/v1/notification-preferences')
            ->assertOk()
            ->assertJsonPath('preferences.order_updates', true)
            ->assertJsonPath('preferences.promos', false);

        $this->actingAs($buyer, 'sanctum')->postJson('/api/v1/wishlist/'.$order->items()->value('product_id'))
            ->assertOk();
        $this->actingAs($buyer, 'sanctum')->getJson('/api/v1/wishlist')
            ->assertOk()
            ->assertJsonPath('data.0.name', 'Cancelable Mug');

        $this->actingAs($buyer, 'sanctum')->postJson('/api/v1/conversations', [
            'order_number' => $order->order_number,
            'message' => 'Is this still available today?',
        ])->assertCreated()->assertJsonStructure(['conversation_id']);

        $this->actingAs($buyer, 'sanctum')->postJson('/api/v1/vouchers/validate', [
            'code' => 'SAVE10',
            'subtotal' => 100,
        ])->assertOk()->assertJsonPath('discount', 10);

        $order->update(['status' => OrderStatus::Delivered]);
        $this->actingAs($buyer, 'sanctum')->postJson('/api/v1/returns', [
            'order_number' => $order->order_number,
            'reason' => 'damaged_item',
            'description' => 'Box arrived crushed.',
        ])->assertCreated();
    }

    public function test_locations_wrap_psgc_payload_for_mobile(): void
    {
        config([
            'services.psgc.token' => 'test-psa-token',
            'services.psgc.version' => 'Q2_TEST',
        ]);
        Http::fake([
            'classification.psa.gov.ph/psgc/Q2_TEST/regions*' => Http::response([
                'results' => ['psgc_data' => [
                    ['psgc_code' => '1300000000', 'area_name' => 'National Capital Region'],
                ]],
            ]),
        ]);

        $this->getJson('/api/v1/locations/regions')
            ->assertOk()
            ->assertJsonPath('data.0.code', '1300000000')
            ->assertJsonPath('data.0.psgc_10_digit', '1300000000')
            ->assertJsonPath('data.0.name', 'National Capital Region');
    }

    public function test_logistics_dashboard_uses_honest_counts_and_scan_rejects_invalid_transitions(): void
    {
        $hub = $this->userWithRole('logistics');
        LogisticsProfile::query()->create([
            'user_id' => $hub->id,
            'hub_business_name' => 'Laguna Central Hub',
            'hub_code' => 'HUB-LAG-01',
        ]);
        [$buyer, $seller, $order] = $this->makePlacedOrder();
        $parcel = Parcel::query()->create([
            'order_id' => $order->id,
            'tracking_number' => 'JEPTESTPARCEL1',
            'status' => OrderStatus::Placed,
        ]);

        $this->actingAs($hub, 'sanctum')->getJson('/api/v1/logistics/dashboard')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.stats.incoming', 0)
            ->assertJsonPath('data.stats.received', 0)
            ->assertJsonPath('data.hub_name', 'Laguna Central Hub');

        $this->actingAs($hub, 'sanctum')->postJson('/api/v1/logistics/scan', [
            'identifier' => $parcel->tracking_number,
            'action' => 'receive',
        ])->assertStatus(409)->assertJsonPath('success', false);

        $order->update(['status' => OrderStatus::PickedUp]);
        $parcel->update(['status' => OrderStatus::PickedUp]);

        $this->actingAs($hub, 'sanctum')->postJson('/api/v1/logistics/scan', [
            'identifier' => $parcel->tracking_number,
            'action' => 'receive',
        ])->assertOk()->assertJsonPath('success', true);

        $this->assertSame(OrderStatus::AtSortingCenter, $order->fresh()->status);
        $this->actingAs($hub, 'sanctum')->getJson('/api/v1/logistics/parcels/'.$parcel->tracking_number)
            ->assertOk()
            ->assertJsonPath('data.allowed_actions.0', 'sort');
    }

    public function test_rider_fleet_vehicle_and_pending_remittances(): void
    {
        $hub = $this->userWithRole('logistics');
        $company = LogisticsProfile::query()->create([
            'user_id' => $hub->id,
            'hub_business_name' => 'JEAP Dash Laguna',
            'hub_code' => 'HUB-LAG-01',
        ]);
        $rider = $this->userWithRole('courier');
        CourierProfile::query()->create([
            'user_id' => $rider->id,
            'logistics_profile_id' => $company->id,
            'vehicle_type' => VehicleType::TwoWheels,
            'plate_number' => 'ND-4110',
            'license_number' => 'N01-23-456789',
            'license_expires_at' => now()->addYear(),
            'is_online' => true,
        ]);

        $this->actingAs($rider, 'sanctum')->getJson('/api/v1/rider/fleet')
            ->assertOk()
            ->assertJsonPath('fleet_name', 'JEAP Dash Laguna');
        $this->actingAs($rider, 'sanctum')->getJson('/api/v1/rider/vehicle')
            ->assertOk()
            ->assertJsonPath('vehicle_type_value', '2_wheels');
        $this->actingAs($rider, 'sanctum')->getJson('/api/v1/rider/remittances/pending')
            ->assertOk()
            ->assertJsonPath('total', 0);
        $this->actingAs($rider, 'sanctum')->getJson('/api/v1/rider/documents')
            ->assertOk()
            ->assertJsonStructure(['documents', 'summary']);
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
        SellerProfile::query()->create([
            'user_id' => $seller->id,
            'business_name' => 'Test Shop',
        ]);
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

        return [$product->load('seller'), $variant];
    }

    private function makePlacedOrder(): array
    {
        $buyer = $this->userWithRole('buyer');
        [$product, $variant] = $this->makeListedProduct('Cancelable Mug', 'cancelable-mug', 12, 18, 'kitchen');
        $seller = $product->seller;
        $order = Order::query()->create([
            'checkout_group_id' => 'group-mobile-1',
            'order_number' => 'JEAP-MOBILE1',
            'buyer_id' => $buyer->id,
            'seller_id' => $seller->id,
            'status' => OrderStatus::Placed,
            'subtotal' => 12,
            'shipping_fee' => 50,
            'discount' => 0,
            'total' => 62,
            'shipping_address_snapshot' => [
                'recipient_name' => 'Mobile Buyer',
                'phone' => '09170000000',
                'street_line' => '1 Test Street',
                'city_name' => 'Manila',
            ],
            'placed_at' => now(),
        ]);
        OrderItem::query()->create([
            'order_id' => $order->id,
            'product_id' => $product->id,
            'product_variant_id' => $variant->id,
            'name' => $product->name,
            'sku' => $variant->sku,
            'quantity' => 2,
            'stock_before' => 20,
            'stock_after' => 18,
            'unit_price' => 12,
            'subtotal' => 24,
        ]);
        Commission::query()->create([
            'order_id' => $order->id,
            'seller_id' => $seller->id,
            'rate' => 20,
            'amount' => 2.40,
            'status' => 'accrued',
        ]);

        return [$buyer, $seller, $order, $variant];
    }
}
