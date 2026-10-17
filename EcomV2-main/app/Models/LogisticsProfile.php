<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\MorphMany;

class LogisticsProfile extends Model
{
    protected $fillable = [
        'user_id',
        'hub_business_name',
        'hub_code',
        'sec_registration_number',
        'tin',
        'contact_position',
        'service_areas',
    ];

    protected function casts(): array
    {
        return ['service_areas' => 'array'];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function addresses(): MorphMany
    {
        return $this->morphMany(Address::class, 'addressable');
    }

    public function riders(): HasMany
    {
        return $this->hasMany(CourierProfile::class);
    }
}
