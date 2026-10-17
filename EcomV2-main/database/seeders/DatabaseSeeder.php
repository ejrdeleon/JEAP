<?php

namespace Database\Seeders;

use App\Models\DeliveryArea;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $this->call([
            RoleSeeder::class,
            AdminUserSeeder::class,
            CatalogSeeder::class,
        ]);

        DeliveryArea::query()->firstOrCreate(
            ['code' => 'AREA-A'],
            ['name' => 'Area A — Santa Cruz', 'description' => 'Laguna hub sample coverage', 'is_active' => true]
        );
    }
}
