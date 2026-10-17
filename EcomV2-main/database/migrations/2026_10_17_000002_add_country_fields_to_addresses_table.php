<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('addresses', function (Blueprint $table): void {
            $table->string('country_code', 2)->nullable()->after('phone');
            $table->string('country_name')->nullable()->after('country_code');
        });

        DB::table('addresses')
            ->whereNull('country_code')
            ->update(['country_code' => 'PH', 'country_name' => 'Philippines']);
    }

    public function down(): void
    {
        Schema::table('addresses', function (Blueprint $table): void {
            $table->dropColumn(['country_code', 'country_name']);
        });
    }
};
