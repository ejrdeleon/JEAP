<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ReturnRequest extends Model
{
    protected $fillable = [
        'order_id', 'buyer_id', 'seller_id', 'reason',
        'description', 'evidence_paths', 'status', 'admin_notes', 'resolved_at',
    ];

    protected function casts(): array
    {
        return [
            'evidence_paths' => 'array',
            'resolved_at' => 'datetime',
        ];
    }

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    public function buyer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'buyer_id');
    }

    public function seller(): BelongsTo
    {
        return $this->belongsTo(User::class, 'seller_id');
    }

    public function refundPayments(): HasMany
    {
        return $this->hasMany(Payment::class, 'return_request_id');
    }
}
