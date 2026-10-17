<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('delivery_assignments', function (Blueprint $table): void {
            $table->string('proof_of_delivery_path')->nullable()->after('delivered_at');
        });
    }

    public function down(): void
    {
        Schema::table('delivery_assignments', function (Blueprint $table): void {
            $table->dropColumn('proof_of_delivery_path');
        });
    }
};
