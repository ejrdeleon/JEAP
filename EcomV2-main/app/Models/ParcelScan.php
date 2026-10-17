<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ParcelScan extends Model
{
    protected $fillable = [
        'parcel_id',
        'scanned_by',
        'location_type',
        'location_id',
        'notes',
    ];

    public function parcel(): BelongsTo
    {
        return $this->belongsTo(Parcel::class);
    }
}
