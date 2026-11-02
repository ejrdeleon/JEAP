<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (! Schema::hasColumn('users', 'status_reason')) {
                $table->string('status_reason', 500)->nullable()->after('status');
            }
            if (! Schema::hasColumn('users', 'status_changed_by')) {
                $table->foreignId('status_changed_by')->nullable()->after('status_reason')->constrained('users')->nullOnDelete();
            }
            if (! Schema::hasColumn('users', 'status_changed_at')) {
                $table->timestamp('status_changed_at')->nullable()->after('status_changed_by');
            }
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (Schema::hasColumn('users', 'status_changed_by')) {
                $table->dropConstrainedForeignId('status_changed_by');
            }
            foreach (['status_reason', 'status_changed_at'] as $column) {
                if (Schema::hasColumn('users', $column)) {
                    $table->dropColumn($column);
                }
            }
        });
    }
};
