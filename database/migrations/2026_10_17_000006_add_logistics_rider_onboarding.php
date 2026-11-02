<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('courier_profiles', function (Blueprint $table): void {
            $table->foreignId('logistics_profile_id')->nullable()->after('user_id')->constrained()->cascadeOnDelete();
            $table->string('license_number', 16)->nullable()->unique();
            $table->date('license_expires_at')->nullable();
            $table->boolean('is_online')->default(false);
            $table->unique('plate_number');
        });

        Schema::create('rider_activation_tokens', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained()->cascadeOnDelete();
            $table->string('token_hash');
            $table->timestamp('expires_at');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('rider_activation_tokens');
        Schema::table('courier_profiles', function (Blueprint $table): void {
            $table->dropUnique(['license_number']);
            $table->dropUnique(['plate_number']);
            $table->dropConstrainedForeignId('logistics_profile_id');
            $table->dropColumn(['license_number', 'license_expires_at', 'is_online']);
        });
    }
};
