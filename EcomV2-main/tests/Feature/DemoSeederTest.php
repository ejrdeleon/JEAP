<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class DemoSeederTest extends TestCase
{
    use RefreshDatabase;

    public function test_seeding_resets_passwords_for_existing_demo_accounts(): void
    {
        $demoAccounts = [
            'admin@jeap.test',
            'hub@jeap.test',
            'seller@jeap.test',
            'buyer@jeap.test',
            'rider@jeap.test',
        ];

        foreach ($demoAccounts as $email) {
            User::factory()->create([
                'email' => $email,
                'password' => 'old-password',
            ]);
        }

        $this->seed();

        $expectedPassword = (string) env('SEED_USER_PASSWORD', 'password');

        foreach ($demoAccounts as $email) {
            $this->assertTrue(Hash::check($expectedPassword, User::query()->where('email', $email)->firstOrFail()->password));
        }

        $this->assertTrue(User::query()->where('email', 'buyer@jeap.test')->firstOrFail()->hasRole('buyer'));
        $rider = User::query()->where('email', 'rider@jeap.test')->firstOrFail();
        $this->assertTrue($rider->hasRole('courier'));
        $this->assertNotNull($rider->courierProfile);
    }
}
