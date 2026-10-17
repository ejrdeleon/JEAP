<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('seller_profiles', function (Blueprint $table): void {
            $table->string('description', 500)->nullable();
            $table->string('contact_phone', 32)->nullable();
            $table->string('logo_path')->nullable();
            $table->string('banner_path')->nullable();
            $table->boolean('vacation_mode')->default(false);
        });
    }

    public function down(): void
    {
        Schema::table('seller_profiles', function (Blueprint $table): void {
            $table->dropColumn(['description', 'contact_phone', 'logo_path', 'banner_path', 'vacation_mode']);
        });
    }
};
