<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('contact_messages', function (Blueprint $table) {
            $table->id();
            $table->string('full_name', 120);
            $table->string('email');
            $table->string('category', 24);
            $table->string('order_number', 80)->nullable();
            $table->text('message');
            $table->timestamps();
            $table->index(['category', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('contact_messages');
    }
};
