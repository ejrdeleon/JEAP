<?php

namespace Tests\Feature;

use App\Enums\UserStatus;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class LogoutPageTest extends TestCase
{
    use RefreshDatabase;

    public function test_guest_logout_page_explains_they_are_signed_out(): void
    {
        $this->get('/logout')
            ->assertOk()
            ->assertSee("You're signed out", false)
            ->assertSee('Continue shopping')
            ->assertSee('Log in')
            ->assertSee('Sign up')
            ->assertDontSee('go back')
            ->assertDontSee('Your session expired');
    }

    public function test_signed_in_buyer_sees_a_sign_out_confirm_page(): void
    {
        $this->seed(RoleSeeder::class);
        $buyer = User::factory()->create(['status' => UserStatus::Active]);
        $buyer->assignRole('buyer');

        $this->actingAs($buyer)
            ->get('/logout')
            ->assertOk()
            ->assertSee('Sign out of JEAP?')
            ->assertSee('Stay signed in');
    }

    public function test_stale_logout_post_opens_the_signed_out_page(): void
    {
        $this->post('/logout', ['_token' => 'expired'])
            ->assertRedirect(route('logout.notice'));
    }
}
