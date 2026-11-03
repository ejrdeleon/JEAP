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

class StorefrontProductPageTest extends TestCase
{
    use RefreshDatabase;

    public function test_product_page_shows_purchase_details_and_related_listings(): void
    {
        $this->seed(RoleSeeder::class);
        $seller = User::factory()->create(['status' => UserStatus::Active]);
        $seller->assignRole('seller');
        $category = Category::query()->create(['name' => 'Kitchen', 'slug' => 'kitchen', 'is_active' => true]);
        $product = $this->listedProduct($seller, $category, 'Air Purifier with HEPA Filter', 'air-purifier-with-hepa-filter', 489, 619);
        $this->listedProduct($seller, $category, 'Durotan Manual Espresso Machine', 'durotan-manual-espresso-machine', 489);

        $this->get(route('products.show', $product->slug))
            ->assertOk()
            ->assertSee('Air Purifier with HEPA Filter')
            ->assertSee('Add To Cart')
            ->assertSee('Cash on Delivery')
            ->assertSee('About this product')
            ->assertSee('You may also like')
            ->assertSee('Durotan Manual Espresso Machine')
            ->assertSee('₱489.00')
            ->assertSee('₱619.00')
            ->assertDontSee('frequently bought together')
            ->assertSee('data-quantity-decrease', false)
            ->assertSee('Log in to chat with seller');
    }

    private function listedProduct(
        User $seller,
        Category $category,
        string $name,
        string $slug,
        float $price,
        ?float $compareAt = null,
    ): Product {
        $product = Product::query()->create([
            'seller_id' => $seller->id,
            'category_id' => $category->id,
            'name' => $name,
            'slug' => $slug,
            'description' => $name.' available on JEAP and delivered by JEAP Dash.',
            'status' => 'active',
        ]);
        ProductVariant::query()->create([
            'product_id' => $product->id,
            'sku' => strtoupper(str_replace('-', '', substr($slug, 0, 12))),
            'price' => $price,
            'compare_at_price' => $compareAt,
            'stock' => 20,
            'is_active' => true,
        ]);

        return $product;
    }
}
