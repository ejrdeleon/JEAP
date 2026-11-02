<?php

namespace App\Models;

use App\Enums\ReviewStatus;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class RegistrationReview extends Model
{
    protected $fillable = [
        'user_id',
        'reviewer_id',
        'decision',
        'notes',
        'notified_at',
    ];

    protected function casts(): array
    {
        return [
            'decision' => ReviewStatus::class,
            'notified_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function reviewer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reviewer_id');
    }
}
