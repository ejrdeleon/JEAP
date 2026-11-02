<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DeliveryAttempt extends Model
{
    protected $fillable = [
        'delivery_assignment_id',
        'attempt_no',
        'failed_reason',
        'reschedule_at',
        'notes',
    ];

    protected function casts(): array
    {
        return [
            'reschedule_at' => 'datetime',
        ];
    }

    public function assignment(): BelongsTo
    {
        return $this->belongsTo(DeliveryAssignment::class, 'delivery_assignment_id');
    }
}
