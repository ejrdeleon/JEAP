<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Role;
use Spatie\Permission\PermissionRegistrar;

class RoleSeeder extends Seeder
{
    public function run(): void
    {
        app()[PermissionRegistrar::class]->forgetCachedPermissions();

        foreach (['buyer', 'seller', 'courier', 'logistics', 'admin', 'super-admin'] as $role) {
            Role::findOrCreate($role, 'web');
        }
    }
}
