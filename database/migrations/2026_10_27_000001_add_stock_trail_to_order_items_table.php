<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('order_items', function (Blueprint $table) {
            if (! Schema::hasColumn('order_items', 'stock_before')) {
                $table->unsignedInteger('stock_before')->nullable()->after('quantity');
            }
            if (! Schema::hasColumn('order_items', 'stock_after')) {
                $table->unsignedInteger('stock_after')->nullable()->after('stock_before');
            }
        });
    }

    public function down(): void
    {
        Schema::table('order_items', function (Blueprint $table) {
            foreach (['stock_after', 'stock_before'] as $column) {
                if (Schema::hasColumn('order_items', $column)) {
                    $table->dropColumn($column);
                }
            }
        });
    }
};
