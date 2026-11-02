<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('shipments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained()->unique()->cascadeOnDelete();
            $table->string('tracking_number', 24)->unique();
            $table->foreignId('courier_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('courier_name')->default('JEAP Dash');
            $table->string('status', 32)->default('order_placed');
            $table->string('current_hub')->nullable();
            $table->string('proof_of_delivery')->nullable();
            $table->string('recipient_name')->nullable();
            $table->date('estimated_delivery_date')->nullable();
            $table->timestamp('delivered_at')->nullable();
            $table->timestamps();

            $table->index('tracking_number');
            $table->index('status');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('shipments');
    }
};
