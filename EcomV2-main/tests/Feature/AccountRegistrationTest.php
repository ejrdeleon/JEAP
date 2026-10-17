<?php

namespace Tests\Feature;

use App\Enums\UserStatus;
use App\Models\Category;
use App\Models\EmailVerificationCode;
use App\Models\User;
use App\Notifications\EmailVerificationCodeNotification;
use Database\Seeders\CatalogSeeder;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;

class AccountRegistrationTest extends TestCase
{
    use RefreshDatabase;

    public function test_buyer_registration_normalizes_contact_data_and_verifies_email_with_a_five_minute_code(): void
    {
        $this->seed(RoleSeeder::class);
        Notification::fake();

        $this->post(route('register'), [
            'first_name' => '  Juan Miguel  ',
            'last_name' => 'Dela Cruz',
            'email' => ' Juan.DelaCruz@Example.com ',
            'phone' => '09171234567',
            'birthday' => '1998-05-14',
            'password' => 'Mamimili@2026',
            'password_confirmation' => 'Mamimili@2026',
            'terms' => '1',
        ])->assertRedirect(route('email.verify.show'));

        $user = User::query()->where('email', 'juan.delacruz@example.com')->firstOrFail();
        $this->assertSame('Juan Miguel', $user->first_name);
        $this->assertSame('+639171234567', $user->phone);
        $this->assertSame(UserStatus::Unverified, $user->status);
        $this->assertNotNull($user->birthday);
        $this->assertTrue(Hash::check('Mamimili@2026', $user->password));
        Notification::assertSentTo($user, EmailVerificationCodeNotification::class);

        $notification = Notification::sent($user, EmailVerificationCodeNotification::class)->first();
        $this->assertMatchesRegularExpression('/^\d{6}$/', $notification->code);
        $this->assertTrue(EmailVerificationCode::query()->where('user_id', $user->id)->firstOrFail()->expires_at->between(now()->addMinutes(4), now()->addMinutes(5)->addSecond()));

        $this->post(route('email.verify'), ['code' => $notification->code])
            ->assertRedirect(route('login'));
        $this->assertSame(UserStatus::Active, $user->fresh()->status);
        $this->assertNotNull($user->fresh()->email_verified_at);
        $this->assertDatabaseMissing('email_verification_codes', ['user_id' => $user->id]);
    }

    public function test_invalid_signup_details_are_rejected_and_unverified_users_cannot_sign_in(): void
    {
        $this->seed(RoleSeeder::class);
        Notification::fake();

        $this->from(route('register'))->post(route('register'), [
            'first_name' => 'Jo7',
            'last_name' => 'Dela Cruz',
            'email' => 'not-an-email',
            'phone' => '123',
            'birthday' => now()->subYears(17)->toDateString(),
            'password' => 'weakpass',
            'password_confirmation' => 'different',
        ])->assertRedirect(route('register'))
            ->assertSessionHasErrors(['first_name', 'email', 'phone', 'birthday', 'password', 'terms']);

        $user = User::factory()->create(['status' => UserStatus::Unverified, 'email_verified_at' => null]);
        $user->assignRole('buyer');
        EmailVerificationCode::query()->create([
            'user_id' => $user->id,
            'code_hash' => Hash::make('123456'),
            'expires_at' => now()->addMinutes(5),
            'attempts' => 0,
        ]);

        $this->post(route('login'), ['email' => $user->email, 'password' => 'password'])
            ->assertRedirect(route('email.verify.show'));
        $this->assertGuest();
        $this->get(route('email.verify.show'))->assertOk()->assertSee($user->email);
    }

    public function test_incorrect_expired_and_resent_codes_do_not_verify_the_account(): void
    {
        $this->seed(RoleSeeder::class);
        Notification::fake();
        $user = User::factory()->create(['status' => UserStatus::Unverified, 'email_verified_at' => null]);
        $user->assignRole('buyer');
        $this->withSession(['email_verification_user_id' => $user->id]);

        $code = EmailVerificationCode::query()->create([
            'user_id' => $user->id,
            'code_hash' => Hash::make('123456'),
            'expires_at' => now()->subSecond(),
            'attempts' => 0,
        ]);

        $this->from(route('email.verify.show'))->post(route('email.verify'), ['code' => '123456'])
            ->assertRedirect(route('email.verify.show'))
            ->assertSessionHasErrors('code');
        $this->assertSame(UserStatus::Unverified, $user->fresh()->status);

        $this->post(route('email.verify.resend'))->assertRedirect(route('email.verify.show'));
        $newNotification = Notification::sent($user, EmailVerificationCodeNotification::class)->first();
        $this->assertNotSame('123456', $newNotification->code);
        $this->post(route('email.verify'), ['code' => '123456'])->assertSessionHasErrors('code');
        $this->post(route('email.verify'), ['code' => $newNotification->code])->assertRedirect(route('login'));
        $this->assertSame(UserStatus::Active, $user->fresh()->status);
    }

    public function test_riders_cannot_self_register(): void
    {
        $this->get(route('register.rider'))->assertRedirect(route('login'));
        $this->post(route('register.rider'))->assertRedirect(route('login'));
    }

    public function test_seller_registration_requires_type_specific_files_and_saves_business_address(): void
    {
        $this->seed(RoleSeeder::class);
        $this->seed(CatalogSeeder::class);
        Notification::fake();
        $category = Category::query()->where('is_active', true)->where('is_line_of_business', true)->firstOrFail();

        $this->post(route('register.seller'), [
            'first_name' => 'Maria Clara',
            'last_name' => 'Santos',
            'business_name' => 'Maria Clara Crafts',
            'shop_category_id' => $category->id,
            'seller_type' => 'sole_proprietorship',
            'tin' => '123-456-789-000',
            'email' => 'maria.clara@example.com',
            'phone' => '09189876543',
            'street_line' => '8 Sampaguita Street',
            'region_name' => 'National Capital Region (NCR)',
            'province_name' => 'Metro Manila',
            'city_name' => 'Quezon City',
            'barangay_name' => 'Commonwealth',
            'postal_code' => '1121',
            'password' => 'Tindahan@2026',
            'password_confirmation' => 'Tindahan@2026',
            'terms' => '1',
            'documents' => [
                'government_id' => UploadedFile::fake()->create('id.pdf', 100, 'application/pdf'),
                'dti_certificate' => UploadedFile::fake()->create('dti.pdf', 100, 'application/pdf'),
                'bir_2303' => UploadedFile::fake()->create('bir.pdf', 100, 'application/pdf'),
            ],
        ])->assertRedirect(route('email.verify.show'));

        $seller = User::query()->where('email', 'maria.clara@example.com')->firstOrFail();
        $this->assertSame(UserStatus::Unverified, $seller->status);
        $this->assertSame('sole_proprietorship', $seller->sellerProfile->seller_type);
        $this->assertSame('123456789000', $seller->sellerProfile->tin);
        $this->assertSame('Quezon City', $seller->sellerProfile->addresses()->firstOrFail()->city_name);
        $this->assertCount(3, $seller->kycDocuments);
    }
}
