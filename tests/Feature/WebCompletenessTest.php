<?php

namespace Tests\Feature;

use App\Commerce\CartMerge;
use App\Commerce\InventoryPolicy;
use App\Enums\OrderStatus;
use App\Enums\UserStatus;
use App\Models\Cart;
use App\Models\CartItem;
use App\Models\Category;
use App\Models\Commission;
use App\Models\CourierProfile;
use App\Models\DeliveryAssignment;
use App\Models\LogisticsProfile;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Parcel;
use App\Models\PlatformPolicy;
use App\Models\Product;
use App\Models\ProductVariant;
use App\Models\SellerProfile;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Tests\TestCase;

class WebCompletenessTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
    }

    public function test_help_policies_shipping_and_login_no_longer_show_stubs(): void
    {
        $this->get(route('help'))
            ->assertOk()
            ->assertDontSee('later slices')
            ->assertSee('Track an order')
            ->assertSee('Parcel scan');

        $this->get(route('home'))
            ->assertOk()
            ->assertDontSee('pay.svg')
            ->assertSee('Cash on Delivery');

        $this->get(route('policies.show', 'terms'))
            ->assertOk()
            ->assertSee('Terms of use')
            ->assertSee('Cash on Delivery')
            ->assertSee('Privacy policy')
            ->assertDontSee('later slices');
        $this->get(route('policies.show', 'privacy'))
            ->assertOk()
            ->assertSee('Privacy policy')
            ->assertSee('We do not sell personal data')
            ->assertSee('Terms of use');
        $this->get(route('login'))->assertOk()->assertSee('Forgot password?');
        $this->get(route('password.request'))->assertOk()->assertSee('Forgot password');
        $this->get(route('shipping.services'))->assertOk()->assertDontSee('Logistics public cluster')->assertSee('JEAP Dash');
        $this->get(route('shipping.track', ['tracking_number' => 'UNKNOWN123']))
            ->assertOk()
            ->assertSee('could not find that tracking number');
        $this->get(route('shipping.track', ['tracking_number' => 'jep000000000']))
            ->assertOk()
            ->assertSee('could not find that tracking number');
    }

    public function test_second_individual_seller_apply_does_not_crash_on_blank_sec(): void
    {
        $category = Category::query()->create(['name' => 'Shops', 'slug' => 'shops', 'is_active' => true, 'is_line_of_business' => true]);

        $this->postSellerApply('one@example.com', 'First Shop', '123456789000', $category->id)->assertRedirect();
        $this->postSellerApply('two@example.com', 'Second Shop', '123456789001', $category->id)->assertRedirect();

        $this->assertSame(2, SellerProfile::query()->count());
        $this->assertNull(SellerProfile::query()->where('business_name', 'Second Shop')->value('sec_registration_number'));
    }

    public function test_google_user_can_set_password_without_current_password(): void
    {
        $user = User::factory()->create([
            'google_id' => 'google-sub',
            'password_set_at' => null,
            'status' => UserStatus::Active,
        ]);
        $user->assignRole('buyer');

        $this->actingAs($user)->from(route('account.password'))->post(route('account.password.update'), [
            'password' => 'NewPass123',
            'password_confirmation' => 'NewPass123',
        ])->assertRedirect()->assertSessionHas('toast');

        $this->assertNotNull($user->fresh()->password_set_at);
    }

    public function test_login_cart_merge_respects_ten_unit_cap(): void
    {
        $buyer = User::factory()->create(['status' => UserStatus::Active]);
        $buyer->assignRole('buyer');
        $seller = User::factory()->create(['status' => UserStatus::Active]);
        $variant = $this->makeVariant($seller, 40);

        $userCart = Cart::query()->create(['user_id' => $buyer->id]);
        CartItem::query()->create([
            'cart_id' => $userCart->id,
            'seller_id' => $seller->id,
            'product_variant_id' => $variant->id,
            'quantity' => 8,
            'unit_price' => 10,
        ]);

        $guestCart = Cart::query()->create(['session_id' => 'guest-session']);
        CartItem::query()->create([
            'cart_id' => $guestCart->id,
            'seller_id' => $seller->id,
            'product_variant_id' => $variant->id,
            'quantity' => 5,
            'unit_price' => 10,
        ]);

        CartMerge::sessionIntoUser('guest-session', $buyer);

        $this->assertSame(InventoryPolicy::maxQtyPerProduct(), (int) $userCart->items()->value('quantity'));
        $this->assertFalse(Cart::query()->whereKey($guestCart->id)->exists());
    }

    public function test_after_sale_return_rating_complaint_and_remittance_pay_commission(): void
    {
        [$buyer, $seller, $order, $hub, $rider] = $this->makeCompletedDelivery();

        $this->actingAs($buyer)->post(route('buyer.orders.complaint', $order), [
            'type' => 'seller',
            'body' => 'The parcel arrived late and the box was crushed.',
        ])->assertRedirect()->assertSessionHas('status');

        $this->actingAs($buyer)->post(route('buyer.orders.review', $order), [
            'product_id' => $order->items->first()->product_id,
            'rating' => 5,
            'comment' => 'Still usable.',
        ])->assertRedirect();

        $this->actingAs($buyer)->post(route('buyer.orders.return', $order), [
            'reason' => 'damaged_item',
            'description' => 'Corner of the box was crushed in transit.',
        ])->assertRedirect();

        $return = $order->fresh()->returnRequest;
        $this->actingAs($seller)->post(route('seller.returns.decide', $return), [
            'decision' => 'rejected',
            'notes' => 'Item is still sellable as described.',
        ])->assertRedirect();
        $this->assertSame('rejected', $return->fresh()->status);

        $this->actingAs($rider)->post(route('courier.remittances.store'), [
            'order_ids' => [$order->id],
        ])->assertRedirect()->assertSessionHas('status');

        $remittance = \App\Models\CodRemittance::query()->firstOrFail();
        $this->actingAs($hub)->post(route('logistics.remittances.confirm', $remittance))->assertRedirect();
        $this->assertSame('paid', $order->commission()->first()->fresh()->status);
    }

    public function test_seller_can_toggle_vacation_mode_from_store_profile(): void
    {
        $seller = User::factory()->create(['status' => UserStatus::Active]);
        $seller->assignRole('seller');
        SellerProfile::query()->create([
            'user_id' => $seller->id,
            'business_name' => 'Quiet Shop',
            'contact_phone' => '+639170000000',
        ]);

        $this->actingAs($seller)->put(route('seller.store-profile.update'), [
            'business_name' => 'Quiet Shop',
            'contact_phone' => '09170000000',
            'vacation_mode' => '1',
        ])->assertRedirect();

        $this->assertTrue($seller->sellerProfile()->first()->vacation_mode);
    }

    private function postSellerApply(string $email, string $shop, string $tin, int $categoryId)
    {
        return $this->post(route('register.seller'), [
            'first_name' => 'Seller',
            'last_name' => 'One',
            'email' => $email,
            'phone' => $email === 'one@example.com' ? '09171111111' : '09172222222',
            'password' => 'Seller@2026',
            'password_confirmation' => 'Seller@2026',
            'business_name' => $shop,
            'shop_category_id' => $categoryId,
            'seller_type' => 'individual',
            'tin' => $tin,
            'street_line' => '1 Shop Street',
            'region_name' => 'NCR',
            'city_name' => 'Manila',
            'postal_code' => '1000',
            'terms' => '1',
            'documents' => [
                'government_id' => \Illuminate\Http\UploadedFile::fake()->create('id.pdf', 100, 'application/pdf'),
            ],
        ]);
    }

    private function makeVariant(User $seller, int $stock): ProductVariant
    {
        $category = Category::query()->firstOrCreate(
            ['slug' => 'web-complete'],
            ['name' => 'Web Complete', 'is_active' => true]
        );
        $product = Product::query()->create([
            'seller_id' => $seller->id,
            'category_id' => $category->id,
            'name' => 'Cap Product',
            'slug' => 'cap-product-'.Str::lower(Str::random(6)),
            'status' => 'active',
        ]);

        return ProductVariant::query()->create([
            'product_id' => $product->id,
            'sku' => 'CAP-'.Str::upper(Str::random(6)),
            'price' => 10,
            'stock' => $stock,
            'is_active' => true,
        ]);
    }

    private function makeCompletedDelivery(): array
    {
        $buyer = User::factory()->create(['status' => UserStatus::Active]);
        $buyer->assignRole('buyer');
        $seller = User::factory()->create(['status' => UserStatus::Active]);
        $seller->assignRole('seller');
        $hub = User::factory()->create(['status' => UserStatus::Active]);
        $hub->assignRole('logistics');
        $rider = User::factory()->create(['status' => UserStatus::Active]);
        $rider->assignRole('courier');

        $logistics = LogisticsProfile::query()->create([
            'user_id' => $hub->id,
            'hub_business_name' => 'Test Hub',
        ]);
        CourierProfile::query()->create([
            'user_id' => $rider->id,
            'logistics_profile_id' => $logistics->id,
        ]);

        $variant = $this->makeVariant($seller, 20);
        $order = Order::query()->create([
            'checkout_group_id' => (string) Str::uuid(),
            'order_number' => 'JEP-WEB-1',
            'buyer_id' => $buyer->id,
            'seller_id' => $seller->id,
            'status' => OrderStatus::Completed,
            'subtotal' => 100,
            'shipping_fee' => 50,
            'discount' => 0,
            'total' => 150,
            'placed_at' => now(),
        ]);
        OrderItem::query()->create([
            'order_id' => $order->id,
            'product_id' => $variant->product_id,
            'product_variant_id' => $variant->id,
            'name' => 'Cap Product',
            'sku' => $variant->sku,
            'quantity' => 1,
            'unit_price' => 100,
            'subtotal' => 100,
        ]);
        Commission::query()->create([
            'order_id' => $order->id,
            'seller_id' => $seller->id,
            'rate' => 20,
            'amount' => 20,
            'status' => 'pending',
            'accrued_at' => now(),
        ]);
        $parcel = Parcel::query()->create([
            'order_id' => $order->id,
            'tracking_number' => 'JEPWEBTEST1',
            'status' => OrderStatus::Completed,
        ]);
        DeliveryAssignment::query()->create([
            'parcel_id' => $parcel->id,
            'courier_id' => $rider->id,
            'status' => 'delivered',
            'assigned_at' => now()->subHour(),
            'delivered_at' => now()->subMinutes(10),
        ]);

        return [$buyer, $seller, $order->fresh('items'), $hub, $rider];
    }
}
