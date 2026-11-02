<?php

use App\Models\PlatformPolicy;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (! Schema::hasColumn('users', 'password_set_at')) {
                $table->timestamp('password_set_at')->nullable()->after('password');
            }
        });

        Schema::table('commissions', function (Blueprint $table) {
            if (! Schema::hasColumn('commissions', 'paid_at')) {
                $table->timestamp('paid_at')->nullable()->after('accrued_at');
            }
        });

        Schema::table('complaints', function (Blueprint $table) {
            if (! Schema::hasColumn('complaints', 'admin_notes')) {
                $table->text('admin_notes')->nullable()->after('status');
            }
        });

        Schema::table('contact_messages', function (Blueprint $table) {
            if (! Schema::hasColumn('contact_messages', 'admin_reply')) {
                $table->text('admin_reply')->nullable()->after('message');
            }
            if (! Schema::hasColumn('contact_messages', 'replied_at')) {
                $table->timestamp('replied_at')->nullable()->after('admin_reply');
            }
        });

        DB::table('seller_profiles')->where('sec_registration_number', '')->update(['sec_registration_number' => null]);
        if (Schema::hasTable('logistics_profiles')) {
            DB::table('logistics_profiles')->where('sec_registration_number', '')->update(['sec_registration_number' => null]);
        }

        DB::table('users')->whereNotNull('password')->whereNull('google_id')->whereNull('password_set_at')->update([
            'password_set_at' => now(),
        ]);

        $policies = [
            [
                'key' => 'terms',
                'title' => 'Terms of use',
                'body' => "JEAP is a Philippine marketplace. Orders are delivered by JEAP Dash, our courier.\n\nShoppers pay Cash on Delivery only. Shipping is a flat ₱50 per seller order. A product is listed only when that SKU has at least 10 units in stock, and a cart may hold at most 10 units of the same product.\n\nSellers keep merchandise minus the logistics commission recorded at checkout. JEAP may suspend accounts that break these rules.",
            ],
            [
                'key' => 'privacy',
                'title' => 'Privacy policy',
                'body' => "JEAP collects the name, email, mobile number, and Philippine delivery address you provide so we can create your account, deliver COD orders, and support your purchases.\n\nGoogle sign-in stores a verified email and optional profile photo. We do not sell personal data. You can update your address and profile from your account.",
            ],
            [
                'key' => 'returns',
                'title' => 'Returns policy',
                'body' => "You may request a return after an order is delivered or marked received, if the item is damaged, wrong, or not as described.\n\nThe seller or JEAP admin reviews the request. An approved return voids the logistics commission on that order. Cash collected on delivery is settled through JEAP Dash rider remittance to the sorting center.",
            ],
        ];

        foreach ($policies as $policy) {
            if (Schema::hasTable('platform_policies') && ! PlatformPolicy::query()->where('key', $policy['key'])->exists()) {
                PlatformPolicy::query()->create($policy);
            }
        }
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (Schema::hasColumn('users', 'password_set_at')) {
                $table->dropColumn('password_set_at');
            }
        });
        Schema::table('commissions', function (Blueprint $table) {
            if (Schema::hasColumn('commissions', 'paid_at')) {
                $table->dropColumn('paid_at');
            }
        });
        Schema::table('complaints', function (Blueprint $table) {
            if (Schema::hasColumn('complaints', 'admin_notes')) {
                $table->dropColumn('admin_notes');
            }
        });
        Schema::table('contact_messages', function (Blueprint $table) {
            if (Schema::hasColumn('contact_messages', 'admin_reply')) {
                $table->dropColumn('admin_reply');
            }
            if (Schema::hasColumn('contact_messages', 'replied_at')) {
                $table->dropColumn('replied_at');
            }
        });
    }
};
