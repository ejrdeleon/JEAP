<?php

namespace App\Models;

use App\Enums\ShipmentStatus;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Shipment extends Model
{
    protected $fillable = [
        'order_id',
        'tracking_number',
        'courier_id',
        'courier_name',
        'status',
        'current_hub',
        'proof_of_delivery',
        'recipient_name',
        'estimated_delivery_date',
        'delivered_at',
    ];

    protected function casts(): array
    {
        return [
            'status' => ShipmentStatus::class,
            'estimated_delivery_date' => 'date',
            'delivered_at' => 'datetime',
        ];
    }

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    public function courier(): BelongsTo
    {
        return $this->belongsTo(User::class, 'courier_id');
    }

    public function checkpoints(): HasMany
    {
        return $this->hasMany(ShipmentCheckpoint::class)->orderByDesc('scanned_at')->orderByDesc('id');
    }

    public function getProgressBarStepAttribute(): int
    {
        return match ($this->status) {
            ShipmentStatus::OrderPlaced, ShipmentStatus::Preparing, ShipmentStatus::Packed => 0,
            ShipmentStatus::PickedUp, ShipmentStatus::InTransit, ShipmentStatus::AtHub => 1,
            ShipmentStatus::OutForDelivery, ShipmentStatus::FailedDelivery => 2,
            ShipmentStatus::Delivered => 3,
            default => 0,
        };
    }

    public function getProofOfDeliveryUrlAttribute(): ?string
    {
        if (! $this->proof_of_delivery) {
            return null;
        }

        return route('media.proof', $this);
    }
}
