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

class BuyerWishlistTest extends TestCase
{
    use RefreshDatabase;

    public function test_buyer_can_save_and_remove_products_and_follow_sellers(): void
    {
        $this->seed(RoleSeeder::class);
        $buyer = User::factory()->create(['status' => UserStatus::Active]);
        $buyer->assignRole('buyer');
        $seller = User::factory()->create(['status' => UserStatus::Active]);
        $seller->assignRole('seller');
        $category = Category::query()->create(['name' => 'Home', 'slug' => 'home', 'is_active' => true]);
        $product = Product::query()->create([
            'seller_id' => $seller->id,
            'category_id' => $category->id,
            'name' => 'Lamp',
            'slug' => 'lamp',
            'status' => 'active',
        ]);
        ProductVariant::query()->create([
            'product_id' => $product->id,
            'sku' => 'LAMP-1',
            'price' => 250,
            'stock' => 3,
            'is_active' => true,
        ]);

        $this->actingAs($buyer)->get(route('products.show', $product->slug))
            ->assertOk()->assertSee('Save to wishlist')->assertSee('Follow this store');
        $this->actingAs($buyer)->post(route('buyer.wishlist.save', $product))->assertRedirect();
        $this->actingAs($buyer)->post(route('buyer.sellers.follow', $seller))->assertRedirect();
        $this->actingAs($buyer)->get(route('buyer.wishlist'))
            ->assertOk()->assertSee('Lamp')->assertSee($seller->name);

        $this->actingAs($buyer)->delete(route('buyer.wishlist.remove', $product))->assertRedirect();
        $this->actingAs($buyer)->delete(route('buyer.sellers.unfollow', $seller))->assertRedirect();
        $this->assertDatabaseCount('buyer_wishlists', 0);
        $this->assertDatabaseCount('buyer_followed_sellers', 0);
    }

    public function test_non_buyer_cannot_use_buyer_wishlist_routes(): void
    {
        $this->seed(RoleSeeder::class);
        $seller = User::factory()->create(['status' => UserStatus::Active]);
        $seller->assignRole('seller');

        $this->actingAs($seller)->get(route('buyer.wishlist'))->assertForbidden();
    }
}
