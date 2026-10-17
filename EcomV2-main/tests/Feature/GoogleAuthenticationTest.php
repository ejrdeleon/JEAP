<?php

namespace Tests\Feature;

use App\Enums\UserStatus;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Socialite\Facades\Socialite;
use Laravel\Socialite\Two\User as GoogleUser;
use Tests\TestCase;

class GoogleAuthenticationTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
        config([
            'services.google.client_id' => 'test-client-id',
            'services.google.client_secret' => 'test-client-secret',
            'services.google.redirect' => 'https://jeap.store/auth/google/callback',
        ]);
    }

    public function test_login_and_register_pages_show_google_sign_in(): void
    {
        $this->get(route('login'))->assertOk()->assertSee('Continue with Google')->assertSee(route('google.redirect', ['from' => 'login']));
        $this->get(route('register'))->assertOk()->assertSee('Continue with Google')->assertSee(route('google.redirect', ['from' => 'register']));
    }

    public function test_google_redirect_uses_authorization_state_and_remembers_safe_source(): void
    {
        $response = $this->get(route('google.redirect', ['from' => 'register']));
        $response->assertRedirect();
        $this->assertStringStartsWith('https://accounts.google.com/o/oauth2/auth?', $response->headers->get('Location'));

        $this->assertNotEmpty(session('state'));
        $this->assertSame('register', session('auth.google.source'));
    }

    public function test_verified_google_buyer_is_created_but_remains_pending_approval(): void
    {
        Socialite::fake('google', $this->googleUser());

        $this->withSession(['auth.google.source' => 'register'])
            ->get(route('google.callback'))
            ->assertRedirect(route('register'))
            ->assertSessionHasErrors('google');

        $user = User::where('email', 'google.buyer@example.com')->firstOrFail();
        $this->assertSame('google-sub-1', $user->google_id);
        $this->assertSame(UserStatus::PendingApproval, $user->status);
        $this->assertTrue($user->hasRole('buyer'));
        $this->assertGuest();
    }

    public function test_verified_google_email_links_existing_user_without_changing_role_or_status(): void
    {
        $seller = User::factory()->create([
            'email' => 'google.buyer@example.com',
            'status' => UserStatus::PendingApproval,
        ]);
        $seller->assignRole('seller');
        Socialite::fake('google', $this->googleUser());

        $this->get(route('google.callback'))->assertSessionHasErrors('google');

        $this->assertSame($seller->id, User::where('google_id', 'google-sub-1')->value('id'));
        $this->assertSame(UserStatus::PendingApproval, $seller->fresh()->status);
        $this->assertTrue($seller->fresh()->hasRole('seller'));
        $this->assertSame(1, User::where('email', 'google.buyer@example.com')->count());
        $this->assertGuest();
    }

    public function test_missing_or_unverified_google_email_is_rejected_without_creating_account(): void
    {
        Socialite::fake('google', $this->googleUser(['email_verified' => false]));

        $this->get(route('google.callback'))->assertSessionHasErrors('google');

        $this->assertDatabaseMissing('users', ['email' => 'google.buyer@example.com']);
    }

    public function test_suspended_linked_account_cannot_sign_in(): void
    {
        $user = User::factory()->create([
            'email' => 'google.buyer@example.com',
            'google_id' => 'google-sub-1',
            'status' => UserStatus::Suspended,
        ]);
        $user->assignRole('buyer');
        Socialite::fake('google', $this->googleUser());

        $this->get(route('google.callback'))->assertSessionHasErrors('google');

        $this->assertGuest();
    }

    public function test_active_linked_google_account_signs_in_to_existing_buyer_destination(): void
    {
        $user = User::factory()->create([
            'email' => 'google.buyer@example.com',
            'google_id' => 'google-sub-1',
            'status' => UserStatus::Active,
        ]);
        $user->assignRole('buyer');
        Socialite::fake('google', $this->googleUser());

        $this->get(route('google.callback'))->assertRedirect(route('buyer.home'));

        $this->assertAuthenticatedAs($user);
    }

    public function test_cancelled_google_login_returns_to_original_auth_page(): void
    {
        $this->withSession(['auth.google.source' => 'register'])
            ->get(route('google.callback', ['error' => 'access_denied']))
            ->assertRedirect(route('register'))
            ->assertSessionHasErrors('google');
    }

    public function test_callback_rejects_missing_or_mismatched_oauth_state(): void
    {
        $this->get(route('google.callback', ['code' => 'authorization-code', 'state' => 'not-the-session-state']))
            ->assertRedirect(route('login'))
            ->assertSessionHasErrors('google');

        $this->assertDatabaseMissing('users', ['email' => 'google.buyer@example.com']);
    }

    private function googleUser(array $overrides = []): GoogleUser
    {
        return GoogleUser::fake(array_merge([
            'id' => 'google-sub-1',
            'name' => 'Google Buyer',
            'email' => 'google.buyer@example.com',
            'email_verified' => true,
        ], $overrides));
    }
}
