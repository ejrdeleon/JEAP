<?php

namespace App\Models;

use App\Enums\ShipmentStatus;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ShipmentCheckpoint extends Model
{
    protected $fillable = [
        'shipment_id',
        'created_by',
        'status',
        'title',
        'location',
        'notes',
        'scanned_at',
    ];

    protected function casts(): array
    {
        return [
            'status' => ShipmentStatus::class,
            'scanned_at' => 'datetime',
        ];
    }

    public function shipment(): BelongsTo
    {
        return $this->belongsTo(Shipment::class);
    }

    public function loggedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }
}
