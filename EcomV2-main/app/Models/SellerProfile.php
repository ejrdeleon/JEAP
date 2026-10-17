<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SellerProfile extends Model
{
    protected $fillable = [
        'user_id',
        'business_name',
        'line_of_business_category_id',
        'dti_number',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function lineOfBusiness(): BelongsTo
    {
        return $this->belongsTo(Category::class, 'line_of_business_category_id');
    }
}
