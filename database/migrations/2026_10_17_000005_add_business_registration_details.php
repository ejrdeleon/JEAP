<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table): void {
            $table->timestamp('terms_accepted_at')->nullable();
        });

        Schema::table('seller_profiles', function (Blueprint $table): void {
            $table->string('seller_type', 32)->nullable();
            $table->string('tin', 12)->nullable()->unique();
            $table->string('sec_registration_number', 11)->nullable()->unique();
            $table->unique('business_name');
        });

        Schema::table('logistics_profiles', function (Blueprint $table): void {
            $table->string('sec_registration_number', 11)->nullable()->unique();
            $table->string('tin', 12)->nullable()->unique();
            $table->unique('hub_business_name');
            $table->string('contact_position', 120)->nullable();
            $table->json('service_areas')->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('logistics_profiles', function (Blueprint $table): void {
            $table->dropUnique(['sec_registration_number']);
            $table->dropUnique(['tin']);
            $table->dropUnique(['hub_business_name']);
            $table->dropColumn(['sec_registration_number', 'tin', 'contact_position', 'service_areas']);
        });
        Schema::table('seller_profiles', function (Blueprint $table): void {
            $table->dropUnique(['business_name']);
            $table->dropUnique(['tin']);
            $table->dropUnique(['sec_registration_number']);
            $table->dropColumn(['seller_type', 'tin', 'sec_registration_number']);
        });
        Schema::table('users', function (Blueprint $table): void {
            $table->dropColumn('terms_accepted_at');
        });
    }
};
