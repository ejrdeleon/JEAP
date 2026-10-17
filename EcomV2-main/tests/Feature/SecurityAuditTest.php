<?php

namespace Tests\Feature;

use App\Enums\UserStatus;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class SecurityAuditTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_routes_require_authentication(): void
    {
        $this->get('/admin')->assertRedirect(route('login'));
        $this->get('/admin/users')->assertRedirect(route('login'));
        $this->get('/seller')->assertRedirect(route('login'));
        $this->get('/logistics')->assertRedirect(route('login'));
        $this->get('/courier')->assertRedirect(route('login'));
    }

    public function test_api_me_requires_authentication(): void
    {
        $this->get('/api/v1/me')->assertUnauthorized();
        $this->getJson('/api/v1/me')->assertUnauthorized();
    }

    public function test_security_headers_are_present(): void
    {
        $this->get('/')->assertOk()
            ->assertHeader('X-Frame-Options', 'SAMEORIGIN')
            ->assertHeader('X-Content-Type-Options', 'nosniff')
            ->assertHeader('Referrer-Policy', 'strict-origin-when-cross-origin')
            ->assertHeader('Permissions-Policy', 'camera=(), microphone=(), geolocation=(self), payment=()');
    }

    public function test_seeded_style_password_can_log_in(): void
    {
        $this->seed(RoleSeeder::class);

        $user = User::factory()->create([
            'email' => 'admin-login@jeap.test',
            'status' => UserStatus::Active,
            'password' => 'password',
        ]);
        $user->assignRole('admin');

        $this->from('/login')->post('/login', [
            'email' => 'admin-login@jeap.test',
            'password' => 'password',
        ])->assertRedirect(route('admin.dashboard'));
    }

    public function test_admin_login_is_not_sent_to_another_role_dashboard(): void
    {
        $this->seed(RoleSeeder::class);

        $user = User::factory()->create([
            'email' => 'admin-intended@jeap.test',
            'status' => UserStatus::Active,
            'password' => 'password',
        ]);
        $user->assignRole('admin');

        $this->get('/seller')->assertRedirect(route('login'));

        $this->from('/login')->post('/login', [
            'email' => 'admin-intended@jeap.test',
            'password' => 'password',
        ])->assertRedirect(route('admin.dashboard'));
    }

    public function test_login_is_rate_limited(): void
    {
        for ($i = 0; $i < 5; $i++) {
            $this->from('/login')->post('/login', [
                'email' => 'rate-limit@example.test',
                'password' => 'invalid-password',
            ]);
        }

        $this->from('/login')->post('/login', [
            'email' => 'rate-limit@example.test',
            'password' => 'invalid-password',
        ])->assertStatus(429);
    }

    public function test_each_role_can_log_out_without_page_expired(): void
    {
        $this->seed(RoleSeeder::class);

        $homes = [
            'admin' => '/admin',
            'seller' => '/seller',
            'logistics' => '/logistics',
            'courier' => '/courier',
            'buyer' => '/buyer',
        ];

        foreach ($homes as $role => $home) {
            $user = User::factory()->create([
                'status' => UserStatus::Active,
                'password' => 'password',
            ]);
            $user->syncRoles([$role]);

            $this->actingAs($user)
                ->from($home)
                ->post('/logout')
                ->assertRedirect(route('home'))
                ->assertStatus(302);

            $this->assertGuest();
        }
    }

    public function test_dashboard_logout_form_posts_to_current_origin(): void
    {
        $this->seed(RoleSeeder::class);

        $user = User::factory()->create([
            'status' => UserStatus::Active,
            'password' => 'password',
        ]);
        $user->syncRoles(['seller']);

        $this->actingAs($user)
            ->get('/seller')
            ->assertOk()
            ->assertSee('action="/logout"', false);
    }
}
