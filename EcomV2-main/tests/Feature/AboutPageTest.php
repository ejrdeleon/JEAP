<?php

namespace Tests\Feature;

use App\Models\User;
use Database\Seeders\CatalogSeeder;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AboutPageTest extends TestCase
{
    use RefreshDatabase;

    public function test_about_page_shows_current_marketplace_information_and_real_links(): void
    {
        $this->get('/about')
            ->assertOk()
            ->assertSee('A better way to shop from marketplace sellers.')
            ->assertSee('Cash on Delivery')
            ->assertSee(route('products.index'))
            ->assertDontSee('$12,5M')
            ->assertDontSee('our showreel');
    }

    public function test_storefront_uses_peso_prices_and_has_no_subscription_form(): void
    {
        $this->seed(RoleSeeder::class);
        $this->seed(CatalogSeeder::class);

        $this->get('/')
            ->assertOk()
            ->assertSee('₱')
            ->assertDontSee('COD only in v1')
            ->assertDontSee('PHP pricing')
            ->assertDontSee('$')
            ->assertDontSee('Subscribe to get updates on deals')
            ->assertDontSee('USD');
    }

    public function test_guest_topbar_invites_sign_up_without_a_fake_discount(): void
    {
        $this->get('/')
            ->assertOk()
            ->assertSee('Sign up')
            ->assertSee('Cash on Delivery')
            ->assertDontSee('Get 10%')
            ->assertDontSee('Register Now');

        $user = User::factory()->create();

        $this->actingAs($user)->get('/')
            ->assertOk()
            ->assertDontSee('Get 10% DISCOUNT');
    }
}
