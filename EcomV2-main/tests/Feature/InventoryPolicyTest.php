<?php

namespace Tests\Feature;

use App\Commerce\InventoryPolicy;
use App\Enums\UserStatus;
use App\Models\Cart;
use App\Models\Category;
use App\Models\Product;
use App\Models\ProductVariant;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class InventoryPolicyTest extends TestCase
{
    use RefreshDatabase;

    public function test_products_below_minimum_stock_are_hidden_from_the_catalog(): void
    {
        $this->seed(RoleSeeder::class);
        [$seller, $category] = $this->sellerAndCategory();
        $this->makeProduct($seller, $category, 'Low Stock Fan', 9);
        $this->makeProduct($seller, $category, 'Ready Blender', 12);

        $this->get(route('products.index'))
            ->assertOk()
            ->assertSee('Ready Blender')
            ->assertDontSee('Low Stock Fan');
    }

    public function test_cart_rejects_more_than_ten_units_of_the_same_product(): void
    {
        $this->seed(RoleSeeder::class);
        [$seller, $category] = $this->sellerAndCategory();
        $variant = $this->makeProduct($seller, $category, 'Limited Mug', 40);
        $buyer = User::factory()->create(['status' => UserStatus::Active]);
        $buyer->assignRole('buyer');

        $this->actingAs($buyer)->post(route('cart.add'), [
            'product_variant_id' => $variant->id,
            'quantity' => 10,
        ])->assertRedirect();

        $this->actingAs($buyer)->from(route('products.show', $variant->product->slug))->post(route('cart.add'), [
            'product_variant_id' => $variant->id,
            'quantity' => 1,
        ])->assertRedirect()->assertSessionHasErrors('quantity');

        $this->assertSame(10, Cart::query()->where('user_id', $buyer->id)->first()?->items()->sum('quantity'));
        $this->assertSame(10, InventoryPolicy::maxQtyPerProduct());
        $this->assertSame(50.0, InventoryPolicy::shippingFee());
    }

    private function sellerAndCategory(): array
    {
        $seller = User::factory()->create(['status' => UserStatus::Active]);
        $seller->assignRole('seller');
        $category = Category::query()->create([
            'name' => 'Policy category',
            'slug' => 'policy-category',
            'is_active' => true,
        ]);

        return [$seller, $category];
    }

    private function makeProduct(User $seller, Category $category, string $name, int $stock): ProductVariant
    {
        $product = Product::query()->create([
            'seller_id' => $seller->id,
            'category_id' => $category->id,
            'name' => $name,
            'slug' => str($name)->slug()->toString(),
            'status' => 'active',
        ]);

        return $product->variants()->create([
            'sku' => str($name)->slug()->upper()->toString(),
            'price' => 100,
            'stock' => $stock,
            'is_active' => true,
        ]);
    }
}
