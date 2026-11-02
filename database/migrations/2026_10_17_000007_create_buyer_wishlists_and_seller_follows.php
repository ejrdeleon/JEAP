<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('buyer_wishlists', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('buyer_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('product_id')->constrained()->cascadeOnDelete();
            $table->timestamps();
            $table->unique(['buyer_id', 'product_id']);
        });

        Schema::create('buyer_followed_sellers', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('buyer_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('seller_id')->constrained('users')->cascadeOnDelete();
            $table->timestamps();
            $table->unique(['buyer_id', 'seller_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('buyer_followed_sellers');
        Schema::dropIfExists('buyer_wishlists');
    }
};
