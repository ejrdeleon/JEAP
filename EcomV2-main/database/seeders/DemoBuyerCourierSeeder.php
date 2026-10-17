<?php

namespace Database\Seeders;

use App\Enums\UserStatus;
use App\Models\DeliveryArea;
use App\Models\User;
use Illuminate\Database\Seeder;

class DemoBuyerCourierSeeder extends Seeder
{
    public function run(): void
    {
        $buyer = User::query()->updateOrCreate(
            ['email' => 'buyer@jeap.test'],
            [
                'first_name' => 'Demo',
                'last_name' => 'Buyer',
                'phone' => '09170000002',
                'password' => $this->seedPassword(),
                'email_verified_at' => now(),
            ]
        );
        $buyer->forceFill(['status' => UserStatus::Active])->save();
        $buyer->syncRoles(['buyer']);

        $rider = User::query()->updateOrCreate(
            ['email' => 'rider@jeap.test'],
            [
                'first_name' => 'Demo',
                'last_name' => 'Rider',
                'phone' => '09170000003',
                'password' => $this->seedPassword(),
                'email_verified_at' => now(),
            ]
        );
        $rider->forceFill(['status' => UserStatus::Active])->save();
        $rider->syncRoles(['courier']);

        $rider->courierProfile()->updateOrCreate(
            ['user_id' => $rider->id],
            [
                'vehicle_type' => 'Motorcycle',
                'assigned_delivery_area_id' => DeliveryArea::query()->where('code', 'AREA-A')->value('id'),
                'approved_by' => User::query()->where('email', 'hub@jeap.test')->value('id'),
            ]
        );
    }

    private function seedPassword(): string
    {
        return (string) env('SEED_USER_PASSWORD', 'password');
    }
}
