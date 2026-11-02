<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\MorphTo;

class Address extends Model
{
    protected $fillable = [
        'label',
        'recipient_name',
        'phone',
        'country_code',
        'country_name',
        'region_code',
        'province_code',
        'city_code',
        'barangay_code',
        'region_name',
        'province_name',
        'city_name',
        'barangay_name',
        'street_line',
        'subdivision',
        'postal_code',
        'landmark',
        'delivery_instructions',
        'latitude',
        'longitude',
        'is_default',
    ];

    protected function casts(): array
    {
        return [
            'is_default' => 'boolean',
            'latitude' => 'decimal:7',
            'longitude' => 'decimal:7',
        ];
    }

    public function addressable(): MorphTo
    {
        return $this->morphTo();
    }
}
