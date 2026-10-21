<?php

namespace Tests\Feature;

use App\Enums\UserStatus;
use App\Models\Announcement;
use App\Models\LogisticsProfile;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminPagesTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
    }

    public function test_admin_pages_render_and_super_admin_pages_are_restricted(): void
    {
        $admin = $this->createUserWithRole('admin');

        $this->actingAs($admin)
            ->get('/admin')
            ->assertOk()
            ->assertSee('Admin dashboard');
        $this->actingAs($admin)->get('/admin/users')->assertOk();
        $this->actingAs($admin)->get('/admin/cms')->assertOk();
        $this->actingAs($admin)->get('/admin/disputes')->assertOk();
        $this->actingAs($admin)->get('/admin/reports')->assertOk();
        $this->actingAs($admin)->get('/super-admin')->assertForbidden();

        $superAdmin = $this->createUserWithRole('super-admin');
        $this->actingAs($superAdmin)->get('/super-admin')->assertOk();
        $this->actingAs($superAdmin)->get('/super-admin/admins')->assertOk();
        $this->actingAs($superAdmin)->get('/super-admin/settings')->assertOk();
        $this->actingAs($superAdmin)->get('/admin')->assertOk();
        $this->actingAs($superAdmin)->get('/admin/users')->assertOk();
        $this->actingAs($superAdmin)->get('/logistics')->assertOk();
        LogisticsProfile::query()->create(['user_id' => $admin->id, 'hub_business_name' => 'Test Hub']);
        $this->actingAs($superAdmin)->get('/logistics/riders')->assertOk();
        $this->actingAs($superAdmin)->get('/seller')->assertOk();
        $this->actingAs($superAdmin)->get('/buyer')->assertOk();
    }

    public function test_super_admin_login_redirects_to_the_super_admin_dashboard(): void
    {
        $superAdmin = User::factory()->create([
            'email' => 'super-admin@jeap.test',
            'password' => 'password',
            'status' => UserStatus::Active,
        ]);
        $superAdmin->assignRole('super-admin');

        $this->from('/login')->post('/login', [
            'email' => $superAdmin->email,
            'password' => 'password',
        ])->assertRedirect(route('super-admin.dashboard'));
    }

    public function test_admin_can_manage_marketplace_accounts_but_not_staff(): void
    {
        $admin = $this->createUserWithRole('admin');
        $buyer = $this->createUserWithRole('buyer');

        $this->actingAs($admin)->patch(route('admin.users.status', $buyer), [
            'status' => UserStatus::Suspended->value,
        ])->assertRedirect();
        $this->assertSame(UserStatus::Suspended, $buyer->fresh()->status);

        $this->actingAs($admin)->patch(route('admin.users.status', $admin), [
            'status' => UserStatus::Suspended->value,
        ])->assertForbidden();

        $pending = User::factory()->create(['status' => UserStatus::PendingApproval]);
        $pending->assignRole('buyer');
        $this->actingAs($admin)->patch(route('admin.users.status', $pending), [
            'status' => UserStatus::Active->value,
        ])->assertForbidden();
    }

    public function test_admin_can_publish_announcements_and_super_admin_can_manage_admins_and_policies(): void
    {
        $admin = $this->createUserWithRole('admin');
        $this->actingAs($admin)->post(route('admin.cms.store'), [
            'title' => 'Service update',
            'body' => 'Marketplace maintenance tonight.',
            'audience' => 'all',
            'is_published' => '1',
        ])->assertRedirect();
        $this->assertDatabaseHas('announcements', [
            'title' => 'Service update',
            'is_published' => true,
        ]);

        $superAdmin = $this->createUserWithRole('super-admin');
        $this->actingAs($superAdmin)->post(route('super-admin.admins.store'), [
            'first_name' => 'New',
            'last_name' => 'Operator',
            'email' => 'operator@jeap.test',
            'password' => 'a-very-long-secret',
            'password_confirmation' => 'a-very-long-secret',
        ])->assertRedirect();
        $createdAdmin = User::query()->where('email', 'operator@jeap.test')->firstOrFail();
        $this->assertTrue($createdAdmin->hasRole('admin'));
        $this->assertSame(UserStatus::Active, $createdAdmin->status);

        $this->actingAs($superAdmin)->post(route('super-admin.settings.policies.store'), [
            'key' => 'returns-policy',
            'title' => 'Returns',
            'body' => 'Return policy details.',
        ])->assertRedirect();
        $this->assertDatabaseHas('platform_policies', ['key' => 'returns-policy']);
    }

    public function test_published_announcements_are_shown_to_their_audience(): void
    {
        Announcement::query()->create([
            'title' => 'Buyer service notice',
            'body' => 'This notice is for buyers.',
            'audience' => 'buyers',
            'is_published' => true,
            'published_at' => now(),
        ]);

        $this->get('/')->assertDontSee('Buyer service notice');

        $buyer = $this->createUserWithRole('buyer');
        $this->actingAs($buyer)->get('/')->assertSee('Buyer service notice')->assertSee('This notice is for buyers.');
    }

    private function createUserWithRole(string $role): User
    {
        $user = User::factory()->create([
            'status' => UserStatus::Active,
        ]);
        $user->assignRole($role);

        return $user;
    }
}
