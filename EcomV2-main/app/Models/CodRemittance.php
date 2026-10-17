<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class CodRemittance extends Model
{
    protected $fillable = [
        'courier_id', 'logistics_id', 'amount', 'status', 'notes', 'remitted_at',
    ];

    protected function casts(): array
    {
        return [
            'amount' => 'decimal:2',
            'remitted_at' => 'datetime',
        ];
    }

    public function courier(): BelongsTo
    {
        return $this->belongsTo(User::class, 'courier_id');
    }

    public function logistics(): BelongsTo
    {
        return $this->belongsTo(User::class, 'logistics_id');
    }

    public function orders(): BelongsToMany
    {
        return $this->belongsToMany(Order::class, 'cod_remittance_orders', 'remittance_id', 'order_id')
            ->withPivot('cod_amount')
            ->withTimestamps();
    }
}
