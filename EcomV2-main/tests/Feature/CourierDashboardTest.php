<?php

namespace Tests\Feature;

use App\Enums\UserStatus;
use App\Models\CourierProfile;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CourierDashboardTest extends TestCase
{
    use RefreshDatabase;

    public function test_active_rider_can_manage_availability_and_vehicle_profile(): void
    {
        $this->seed(RoleSeeder::class);
        $rider = User::factory()->create(['status' => UserStatus::Active, 'phone' => '09170000000']);
        $rider->assignRole('courier');
        $profile = CourierProfile::query()->create([
            'user_id' => $rider->id,
            'vehicle_type' => 'motorcycle',
            'plate_number' => 'ABC1234',
            'license_number' => 'N01-22-123456',
            'license_expires_at' => now()->addYear()->toDateString(),
            'is_online' => false,
        ]);

        $this->actingAs($rider)->get(route('courier.dashboard'))
            ->assertOk()->assertSee('Rider dashboard')->assertSee('Pickup assignments')->assertSee('Delivery assignments');
        $this->actingAs($rider)->patch(route('courier.availability'), ['is_online' => 1])
            ->assertRedirect()->assertSessionHas('status', 'You are online and can receive assignments.');
        $this->assertTrue($profile->fresh()->is_online);

        $this->actingAs($rider)->put(route('courier.profile.update'), [
            'phone' => '09171112222',
            'vehicle_type' => 'van',
            'plate_number' => 'XYZ9876',
            'license_number' => 'N01-22-654321',
            'license_expires_at' => now()->addYears(2)->toDateString(),
        ])->assertRedirect()->assertSessionHas('status', 'Rider profile updated.');

        $this->assertDatabaseHas('users', ['id' => $rider->id, 'phone' => '+639171112222']);
        $this->assertDatabaseHas('courier_profiles', ['id' => $profile->id, 'vehicle_type' => 'van', 'plate_number' => 'XYZ9876']);
    }

    public function test_expired_license_cannot_be_set_online(): void
    {
        $this->seed(RoleSeeder::class);
        $rider = User::factory()->create(['status' => UserStatus::Active]);
        $rider->assignRole('courier');
        CourierProfile::query()->create([
            'user_id' => $rider->id,
            'license_expires_at' => now()->subDay()->toDateString(),
        ]);

        $this->actingAs($rider)->from(route('courier.dashboard'))->patch(route('courier.availability'), ['is_online' => 1])
            ->assertRedirect(route('courier.dashboard'))->assertSessionHasErrors('is_online');
        $this->assertDatabaseHas('courier_profiles', ['user_id' => $rider->id, 'is_online' => false]);
    }
}
