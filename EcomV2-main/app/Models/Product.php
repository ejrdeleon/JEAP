<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Product extends Model
{
    protected $fillable = [
        'seller_id',
        'category_id',
        'name',
        'slug',
        'description',
        'status',
        'is_featured',
    ];

    protected function casts(): array
    {
        return [
            'is_featured' => 'boolean',
        ];
    }

    public function scopeNotOnVacation(Builder $query): Builder
    {
        return $query->whereDoesntHave('seller.sellerProfile', fn (Builder $profile) => $profile->where('vacation_mode', true));
    }

    public function scopeListed(Builder $query): Builder
    {
        return $query->notOnVacation()
            ->where('status', 'active')
            ->whereHas('variants', fn (Builder $variants) => $variants->sellable());
    }

    public function seller(): BelongsTo
    {
        return $this->belongsTo(User::class, 'seller_id');
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }

    public function variants(): HasMany
    {
        return $this->hasMany(ProductVariant::class);
    }

    public function images(): HasMany
    {
        return $this->hasMany(ProductImage::class)->orderBy('sort_order');
    }

    public function primaryImage(): ?ProductImage
    {
        return $this->images->first();
    }

    public function defaultVariant(): ?ProductVariant
    {
        return $this->variants->first(fn (ProductVariant $variant) => $variant->isSellable())
            ?? $this->variants->first(fn (ProductVariant $variant) => $variant->is_active);
    }
}
