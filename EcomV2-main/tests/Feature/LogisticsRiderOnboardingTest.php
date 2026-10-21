<?php

namespace Tests\Feature;

use App\Enums\UserStatus;
use App\Models\CourierProfile;
use App\Models\LogisticsProfile;
use App\Models\RiderActivationToken;
use App\Models\User;
use App\Notifications\RiderActivationNotification;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;

class LogisticsRiderOnboardingTest extends TestCase
{
    use RefreshDatabase;

    public function test_only_an_approved_logistics_company_can_add_a_rider_and_the_rider_activates_once(): void
    {
        $this->seed(RoleSeeder::class);
        Notification::fake();
        $logistics = User::factory()->create(['status' => UserStatus::Active]);
        $logistics->assignRole('logistics');
        $company = LogisticsProfile::query()->create(['user_id' => $logistics->id, 'hub_business_name' => 'Bilis Hatid Express']);

        $this->actingAs($logistics)->get(route('logistics.riders'))->assertOk()->assertSee('Add a rider');
        $this->actingAs(User::factory()->create())->post(route('logistics.riders.store'))->assertForbidden();

        $response = $this->actingAs($logistics)->post(route('logistics.riders.store'), [
            'first_name' => 'Pedro Jose',
            'last_name' => 'Garcia',
            'birthday' => '1995-03-22',
            'email' => 'pedrojose.garcia@example.com',
            'phone' => '09451239876',
            'license_number' => 'N01-23-456789',
            'license_expires_at' => now()->addYears(4)->toDateString(),
            'vehicle_type' => 'motorcycle',
            'plate_number' => '123 ABC',
            'documents' => [
                'drivers_license' => UploadedFile::fake()->create('license.pdf', 200, 'application/pdf'),
                'vehicle_registration' => UploadedFile::fake()->create('or-cr.pdf', 200, 'application/pdf'),
            ],
        ])->assertRedirect(route('logistics.riders'));

        $rider = User::query()->where('email', 'pedrojose.garcia@example.com')->firstOrFail();
        $this->assertSame(UserStatus::PendingActivation, $rider->status);
        $this->assertSame($company->id, $rider->courierProfile->logistics_profile_id);
        $this->assertSame('+639451239876', $rider->phone);
        $this->assertCount(2, $rider->kycDocuments);
        Notification::assertSentTo($rider, RiderActivationNotification::class);

        $notification = Notification::sent($rider, RiderActivationNotification::class)->first();
        $this->get($notification->activationUrl)->assertOk()->assertSee('Activate your rider account');
        $parts = parse_url($notification->activationUrl);
        parse_str($parts['query'] ?? '', $query);
        $path = $parts['path'];
        preg_match('#^/rider/activate/(\d+)/([^/]+)$#', $path, $matches);
        $this->assertCount(3, $matches);

        $this->post(route('rider.activate', ['user' => $rider->id, 'token' => $matches[2]]), [
            'password' => 'Rider@2026',
            'password_confirmation' => 'Rider@2026',
        ])->assertRedirect(route('login'));
        $this->assertSame(UserStatus::Active, $rider->fresh()->status);
        $this->assertTrue(Hash::check('Rider@2026', $rider->fresh()->password));
        $this->assertDatabaseMissing('rider_activation_tokens', ['user_id' => $rider->id]);
        $this->get($notification->activationUrl)->assertNotFound();
    }

    public function test_resending_rider_activation_invalidates_the_previous_token_and_old_links_expire(): void
    {
        $this->seed(RoleSeeder::class);
        Notification::fake();
        $logistics = User::factory()->create(['status' => UserStatus::Active]);
        $logistics->assignRole('logistics');
        $company = LogisticsProfile::query()->create(['user_id' => $logistics->id, 'hub_business_name' => 'Agila Cargo']);
        $rider = User::factory()->create(['status' => UserStatus::PendingActivation, 'email_verified_at' => null]);
        $rider->assignRole('courier');
        CourierProfile::query()->create(['user_id' => $rider->id, 'logistics_profile_id' => $company->id]);

        $this->from(route('logistics.riders'))->actingAs($logistics)->post(route('logistics.riders.resend', $rider))->assertRedirect(route('logistics.riders'));
        $first = Notification::sent($rider, RiderActivationNotification::class)->first();
        $this->from(route('logistics.riders'))->actingAs($logistics)->post(route('logistics.riders.resend', $rider))->assertRedirect(route('logistics.riders'));
        $last = Notification::sent($rider, RiderActivationNotification::class)->last();
        $this->assertNotSame($first->activationUrl, $last->activationUrl);
        $this->get($first->activationUrl)->assertNotFound();
        $this->get($last->activationUrl)->assertOk();

        RiderActivationToken::query()->where('user_id', $rider->id)->update(['expires_at' => now()->subSecond()]);
        $this->get($last->activationUrl)->assertNotFound();
    }

    public function test_hub_pages_share_the_same_sidebar(): void
    {
        $this->seed(RoleSeeder::class);
        $logistics = User::factory()->create(['status' => UserStatus::Active]);
        $logistics->assignRole('logistics');
        LogisticsProfile::query()->create(['user_id' => $logistics->id, 'hub_business_name' => 'JEAP Laguna Sorting Center']);

        foreach ([route('logistics.shipments'), route('logistics.couriers'), route('logistics.riders')] as $url) {
            $this->actingAs($logistics)->get($url)
                ->assertOk()
                ->assertSee('Shipments', false)
                ->assertSee('Courier approvals', false)
                ->assertSee('Rider management', false)
                ->assertDontSee('Warehouse', false)
                ->assertDontSee('Rider approvals', false);
        }
    }
}
