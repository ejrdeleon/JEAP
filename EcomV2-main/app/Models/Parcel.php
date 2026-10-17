<?php

namespace App\Models;

use App\Enums\OrderStatus;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Parcel extends Model
{
    protected $fillable = [
        'order_id',
        'tracking_number',
        'waybill_payload',
        'current_hub_id',
        'status',
    ];

    protected function casts(): array
    {
        return [
            'waybill_payload' => 'array',
            'status' => OrderStatus::class,
        ];
    }

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    public function pickupAssignment(): HasOne
    {
        return $this->hasOne(PickupAssignment::class);
    }

    public function deliveryAssignment(): HasOne
    {
        return $this->hasOne(DeliveryAssignment::class);
    }

    public function scans(): HasMany
    {
        return $this->hasMany(ParcelScan::class);
    }
}
