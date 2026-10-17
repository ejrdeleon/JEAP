<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('cod_remittances', function (Blueprint $table) {
            $table->foreignId('logistics_id')->nullable()->change();
        });
    }

    public function down(): void
    {
        DB::table('cod_remittances')
            ->whereNull('logistics_id')
            ->update(['logistics_id' => DB::raw('courier_id')]);

        Schema::table('cod_remittances', function (Blueprint $table) {
            $table->foreignId('logistics_id')->nullable(false)->change();
        });
    }
};
