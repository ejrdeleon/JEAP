<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class DeliveryArea extends Model
{
    protected $fillable = [
        'name',
        'code',
        'description',
        'psgc_coverage',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'psgc_coverage' => 'array',
            'is_active' => 'boolean',
        ];
    }

    public function deliveryAssignments(): HasMany
    {
        return $this->hasMany(DeliveryAssignment::class);
    }
}
