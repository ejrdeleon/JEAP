<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('cod_remittances', function (Blueprint $table) {
            $table->id();
            $table->foreignId('courier_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('logistics_id')->constrained('users')->cascadeOnDelete();
            $table->decimal('amount', 12, 2);
            $table->string('status', 32)->default('pending'); // pending | confirmed
            $table->text('notes')->nullable();
            $table->timestamp('remitted_at')->nullable();
            $table->timestamps();
        });

        Schema::create('cod_remittance_orders', function (Blueprint $table) {
            $table->id();
            $table->foreignId('remittance_id')->constrained('cod_remittances')->cascadeOnDelete();
            $table->foreignId('order_id')->constrained()->cascadeOnDelete();
            $table->decimal('cod_amount', 12, 2);
            $table->timestamps();
            $table->unique(['remittance_id', 'order_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('cod_remittance_orders');
        Schema::dropIfExists('cod_remittances');
    }
};
