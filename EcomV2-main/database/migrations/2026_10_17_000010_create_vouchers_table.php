<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('vouchers')) {
            Schema::create('vouchers', function (Blueprint $table) {
                $table->id();
                $table->string('code', 64)->unique();
                $table->string('type', 32)->default('percent'); // percent | fixed
                $table->decimal('value', 10, 2);
                $table->decimal('min_order', 10, 2)->default(0);
                $table->decimal('max_discount', 10, 2)->nullable();
                $table->unsignedInteger('usage_limit')->nullable();
                $table->unsignedInteger('used_count')->default(0);
                $table->foreignId('seller_id')->nullable()->constrained('users')->nullOnDelete();
                $table->boolean('is_active')->default(true);
                $table->timestamp('starts_at')->nullable();
                $table->timestamp('expires_at')->nullable();
                $table->timestamps();
            });
        } else {
            Schema::table('vouchers', function (Blueprint $table) {
                if (! Schema::hasColumn('vouchers', 'min_order')) {
                    $table->decimal('min_order', 10, 2)->default(0);
                }
                if (! Schema::hasColumn('vouchers', 'max_discount')) {
                    $table->decimal('max_discount', 10, 2)->nullable();
                }
                if (! Schema::hasColumn('vouchers', 'usage_limit')) {
                    $table->unsignedInteger('usage_limit')->nullable();
                }
                if (! Schema::hasColumn('vouchers', 'used_count')) {
                    $table->unsignedInteger('used_count')->default(0);
                }
                if (! Schema::hasColumn('vouchers', 'expires_at')) {
                    $table->timestamp('expires_at')->nullable();
                }
            });
        }

        if (! Schema::hasTable('voucher_usages')) {
            Schema::create('voucher_usages', function (Blueprint $table) {
                $table->id();
                $table->foreignId('voucher_id')->constrained()->cascadeOnDelete();
                $table->foreignId('order_id')->constrained()->cascadeOnDelete();
                $table->foreignId('buyer_id')->constrained('users')->cascadeOnDelete();
                $table->decimal('discount_applied', 10, 2);
                $table->timestamps();
                $table->unique(['voucher_id', 'order_id']);
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('voucher_usages');
        if (Schema::hasColumn('vouchers', 'min_order')) {
            Schema::table('vouchers', function (Blueprint $table) {
                $table->dropColumn(['min_order', 'max_discount', 'usage_limit', 'used_count', 'expires_at']);
            });
        }
    }
};
