<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::table('courier_profiles')
            ->whereIn('vehicle_type', ['motorcycle', 'Motorcycle', 'bike', 'scooter', '2 wheels', 'two_wheels'])
            ->update(['vehicle_type' => '2_wheels']);

        DB::table('courier_profiles')
            ->whereIn('vehicle_type', ['car', 'Car', 'van', 'Van', 'truck', 'Truck', '4 wheels', 'four_wheels'])
            ->update(['vehicle_type' => '4_wheels']);
    }

    public function down(): void
    {
        DB::table('courier_profiles')->where('vehicle_type', '2_wheels')->update(['vehicle_type' => 'motorcycle']);
        DB::table('courier_profiles')->where('vehicle_type', '4_wheels')->update(['vehicle_type' => 'car']);
    }
};
