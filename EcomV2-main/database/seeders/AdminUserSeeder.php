<?php

namespace Database\Seeders;

use App\Enums\UserStatus;
use App\Models\User;
use Illuminate\Database\Seeder;

class AdminUserSeeder extends Seeder
{
    public function run(): void
    {
        User::query()->where('email', 'admin@jmart.test')->update(['email' => 'admin@jeap.test']);
        User::query()->where('email', 'hub@jmart.test')->update(['email' => 'hub@jeap.test']);

        $admin = User::query()->updateOrCreate(
            ['email' => 'admin@jeap.test'],
            [
                'first_name' => 'Platform',
                'last_name' => 'Admin',
                'phone' => '09170000000',
                'password' => $this->seedPassword(),
                'email_verified_at' => now(),
            ]
        );
        $admin->forceFill(['status' => UserStatus::Active])->save();

        $admin->syncRoles(['admin']);

        $hub = User::query()->updateOrCreate(
            ['email' => 'hub@jeap.test'],
            [
                'first_name' => 'Laguna',
                'last_name' => 'Hub',
                'phone' => '09170000001',
                'password' => $this->seedPassword(),
                'email_verified_at' => now(),
            ]
        );
        $hub->forceFill(['status' => UserStatus::Active])->save();
        $hub->syncRoles(['logistics']);
        $hub->logisticsProfile()->updateOrCreate(
            ['user_id' => $hub->id],
            ['hub_business_name' => 'JEAP Laguna Sorting Center', 'hub_code' => 'HUB-LGN']
        );
    }

    private function seedPassword(): string
    {
        return (string) env('SEED_USER_PASSWORD', 'password');
    }
}
