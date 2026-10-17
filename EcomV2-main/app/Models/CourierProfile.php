<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CourierProfile extends Model
{
    protected $fillable = [
        'user_id',
        'logistics_profile_id',
        'vehicle_type',
        'plate_number',
        'license_number',
        'license_expires_at',
        'is_online',
        'assigned_delivery_area_id',
        'approved_by',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function area(): BelongsTo
    {
        return $this->belongsTo(DeliveryArea::class, 'assigned_delivery_area_id');
    }

    public function logisticsProfile(): BelongsTo
    {
        return $this->belongsTo(LogisticsProfile::class);
    }

    protected function casts(): array
    {
        return ['license_expires_at' => 'date', 'is_online' => 'boolean'];
    }
}
