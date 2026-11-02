<?php

use App\Models\PlatformPolicy;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('platform_policies')) {
            PlatformPolicy::query()->where('key', 'terms')->update([
                'body' => "JEAP is a Philippine marketplace. Orders are delivered by JEAP Dash, our courier.\n\nShoppers pay Cash on Delivery only. Shipping is a flat ₱50 per seller order. A product is listed only when that SKU has at least 10 units in stock, and a cart may hold at most 10 units of the same product.\n\nSellers keep merchandise minus the logistics commission recorded at checkout. JEAP may suspend accounts that break these rules.",
            ]);
            PlatformPolicy::query()->where('key', 'returns')->update([
                'body' => "You may request a return after an order is delivered or marked received, if the item is damaged, wrong, or not as described.\n\nThe seller or JEAP admin reviews the request. An approved return voids the logistics commission on that order. Cash collected on delivery is settled through JEAP Dash rider remittance to the sorting center.",
            ]);
        }

        if (Schema::hasTable('products')) {
            DB::table('products')
                ->where('description', 'like', '%with in-house delivery%')
                ->update([
                    'description' => DB::raw("REPLACE(description, 'with in-house delivery', 'and delivered by JEAP Dash')"),
                ]);
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('platform_policies')) {
            PlatformPolicy::query()->where('key', 'terms')->update([
                'body' => "JEAP is a Philippine marketplace with in-house logistics.\n\nShoppers pay Cash on Delivery only. Shipping is a flat ₱50 per seller order. A product is listed only when that SKU has at least 10 units in stock, and a cart may hold at most 10 units of the same product.\n\nSellers keep merchandise minus the logistics commission recorded at checkout. JEAP may suspend accounts that break these rules.",
            ]);
            PlatformPolicy::query()->where('key', 'returns')->update([
                'body' => "You may request a return after an order is delivered or marked received, if the item is damaged, wrong, or not as described.\n\nThe seller or JEAP admin reviews the request. An approved return voids the logistics commission on that order. Cash collected on delivery is settled through rider remittance to the sorting center.",
            ]);
        }

        if (Schema::hasTable('products')) {
            DB::table('products')
                ->where('description', 'like', '%and delivered by JEAP Dash%')
                ->update([
                    'description' => DB::raw("REPLACE(description, 'and delivered by JEAP Dash', 'with in-house delivery')"),
                ]);
        }
    }
};
