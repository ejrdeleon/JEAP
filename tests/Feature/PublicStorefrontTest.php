<?php

namespace Tests\Feature;

use App\Enums\UserStatus;
use App\Models\Category;
use App\Models\Product;
use App\Models\ProductVariant;
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
