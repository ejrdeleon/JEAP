<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Voucher extends Model
{
    protected $fillable = [
        'code', 'type', 'value', 'min_order', 'max_discount',
        'usage_limit', 'used_count', 'seller_id', 'is_active',
        'starts_at', 'expires_at',
    ];

    protected function casts(): array
    {
        return [
            'value' => 'decimal:2',
            'min_order' => 'decimal:2',
            'max_discount' => 'decimal:2',
            'is_active' => 'boolean',
            'starts_at' => 'datetime',
            'expires_at' => 'datetime',
        ];
    }

    public function seller(): BelongsTo
    {
        return $this->belongsTo(User::class, 'seller_id');
    }

    public function usages(): HasMany
    {
        return $this->hasMany(VoucherUsage::class);
    }

    public function isUsableBy(User $buyer, float $orderTotal): bool
    {
        if (! $this->is_active) return false;
        if ($this->starts_at && $this->starts_at->isFuture()) return false;
        if ($this->expires_at && $this->expires_at->isPast()) return false;
        if ($this->usage_limit !== null && $this->used_count >= $this->usage_limit) return false;
        if ($orderTotal < (float) $this->min_order) return false;
        if ($this->usages()->where('buyer_id', $buyer->id)->exists()) return false;

        return true;
    }

    public function computeDiscount(float $subtotal): float
    {
        $discount = $this->type === 'percent'
            ? round($subtotal * (float) $this->value / 100, 2)
            : (float) $this->value;

        if ($this->max_discount !== null) {
            $discount = min($discount, (float) $this->max_discount);
        }

        return min($discount, $subtotal);
    }
}
