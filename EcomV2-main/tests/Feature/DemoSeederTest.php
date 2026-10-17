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
        foreach (['admin@jeap.test', 'hub@jeap.test', 'seller@jeap.test'] as $email) {
            User::factory()->create([
                'email' => $email,
                'password' => 'old-password',
            ]);
        }

        $this->seed();

        $expectedPassword = (string) env('SEED_USER_PASSWORD', 'password');

        foreach (['admin@jeap.test', 'hub@jeap.test', 'seller@jeap.test'] as $email) {
            $this->assertTrue(Hash::check($expectedPassword, User::query()->where('email', $email)->firstOrFail()->password));
        }
    }
}
