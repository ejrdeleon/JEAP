<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('return_requests', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained()->cascadeOnDelete();
            $table->foreignId('buyer_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('seller_id')->constrained('users')->cascadeOnDelete();
            $table->string('reason', 64); // damaged_item | wrong_item | not_as_described | other
            $table->text('description')->nullable();
            $table->json('evidence_paths')->nullable();
            $table->string('status', 32)->default('pending'); // pending | approved | rejected | completed
            $table->text('admin_notes')->nullable();
            $table->timestamp('resolved_at')->nullable();
            $table->timestamps();
        });

        Schema::table('payments', function (Blueprint $table) {
            $table->foreignId('return_request_id')->nullable()->constrained('return_requests')->nullOnDelete()->after('order_id');
        });
    }

    public function down(): void
    {
        Schema::table('payments', function (Blueprint $table) {
            $table->dropForeign(['return_request_id']);
            $table->dropColumn('return_request_id');
        });
        Schema::dropIfExists('return_requests');
    }
};
