<?php

namespace Tests\Feature;

use App\Enums\UserStatus;
use App\Models\Category;
use App\Models\Product;
use App\Models\ProductVariant;
use App\Models\SellerProfile;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PublicStorefrontTest extends TestCase
{
    use RefreshDatabase;

    public function test_public_seller_store_shows_only_live_products_and_filters_categories(): void
    {
        $this->seed(RoleSeeder::class);
        $seller = User::factory()->create(['status' => UserStatus::Active]);
        $seller->assignRole('seller');
        $category = Category::query()->create(['name' => 'Home Goods', 'slug' => 'home-goods', 'is_active' => true]);
        $other = Category::query()->create(['name' => 'Books', 'slug' => 'books', 'is_active' => true]);
        $live = $this->makeProduct($seller, $category, 'Desk Lamp', 'active', 'STORE-001');
        $this->makeProduct($seller, $other, 'Novel', 'active', 'STORE-002');
        $this->makeProduct($seller, $category, 'Draft Lamp', 'draft', 'STORE-003');

        $this->get(route('stores.show', $seller))
            ->assertOk()->assertSee('Desk Lamp')->assertSee('Novel')->assertDontSee('Draft Lamp')
            ->assertSee('Home Goods')->assertSee('Books');
        $this->get(route('stores.show', ['seller' => $seller, 'category' => 'home-goods', 'q' => 'Desk']))
            ->assertOk()->assertSee('Desk Lamp')->assertDontSee('Novel');

        $inactiveSeller = User::factory()->create(['status' => UserStatus::PendingApproval]);
        $inactiveSeller->assignRole('seller');
        $this->get(route('stores.show', $inactiveSeller))->assertNotFound();
    }

    public function test_catalog_search_finds_shops_and_sellers_as_well_as_products(): void
    {
        $this->seed(RoleSeeder::class);
        $seller = User::factory()->create([
            'status' => UserStatus::Active,
            'first_name' => 'Mabini',
            'last_name' => 'Merchant',
        ]);
        $seller->assignRole('seller');
        SellerProfile::query()->create([
            'user_id' => $seller->id,
            'business_name' => 'Mabini Crafts',
        ]);
        $category = Category::query()->create(['name' => 'Home Goods', 'slug' => 'home-goods', 'is_active' => true]);
        $this->makeProduct($seller, $category, 'Desk Lamp', 'active', 'SHOP-001');

        $this->get(route('products.index', ['q' => 'Mabini Crafts']))
            ->assertOk()
            ->assertSee('Shops')
            ->assertSee('Mabini Crafts')
            ->assertSee('Desk Lamp')
            ->assertSee(route('stores.show', $seller), false);

        $this->get(route('products.index', ['q' => 'Mabini Merchant']))
            ->assertOk()
            ->assertSee('Mabini Crafts')
            ->assertSee('Desk Lamp');
    }

    private function makeProduct(User $seller, Category $category, string $name, string $status, string $sku): Product
    {
        $product = Product::query()->create([
            'seller_id' => $seller->id,
            'category_id' => $category->id,
            'name' => $name,
            'slug' => str($name)->slug()->toString(),
            'status' => $status,
        ]);
        ProductVariant::query()->create([
            'product_id' => $product->id,
            'sku' => $sku,
            'price' => 100,
            'stock' => 12,
            'is_active' => true,
        ]);

        return $product;
    }
}
