<?php

namespace App\Commerce;

use App\Enums\UserStatus;
use App\Models\User;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class CatalogSearch
{
    public static function applyToProducts(Builder $query, string $term): Builder
    {
        $like = self::like($term);
        $nameSql = self::personNameSql();

        return $query->where(function (Builder $q) use ($like, $nameSql): void {
            $q->where('name', 'like', $like)
                ->orWhere('description', 'like', $like)
                ->orWhereHas('seller.sellerProfile', fn (Builder $profile) => $profile->where('business_name', 'like', $like))
                ->orWhereHas('seller', function (Builder $seller) use ($like, $nameSql): void {
                    $seller->where('first_name', 'like', $like)
                        ->orWhere('last_name', 'like', $like)
                        ->orWhereRaw($nameSql.' like ?', [$like]);
                });
        });
    }

    public static function shops(string $term, int $limit = 8): Collection
    {
        $like = self::like($term);
        $nameSql = self::personNameSql();

        return User::query()
            ->role('seller')
            ->where('status', UserStatus::Active)
            ->where(function (Builder $query) use ($like, $nameSql): void {
                $query->where('first_name', 'like', $like)
                    ->orWhere('last_name', 'like', $like)
                    ->orWhereRaw($nameSql.' like ?', [$like])
                    ->orWhereHas('sellerProfile', fn (Builder $profile) => $profile->where('business_name', 'like', $like));
            })
            ->with('sellerProfile')
            ->withCount(['products as listed_products_count' => fn (Builder $products) => $products->listed()])
            ->orderByDesc('listed_products_count')
            ->limit($limit)
            ->get();
    }

    private static function like(string $term): string
    {
        return '%'.addcslashes($term, '%_\\').'%';
    }

    private static function personNameSql(): string
    {
        return DB::connection()->getDriverName() === 'sqlite'
            ? "first_name || ' ' || last_name"
            : "CONCAT(first_name, ' ', last_name)";
    }
}
