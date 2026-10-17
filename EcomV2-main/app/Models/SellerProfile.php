<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\MorphMany;

class SellerProfile extends Model
{
    protected $fillable = [
        'user_id',
        'business_name',
        'line_of_business_category_id',
        'dti_number',
        'seller_type',
        'tin',
        'sec_registration_number',
        'description',
        'contact_phone',
        'logo_path',
        'banner_path',
        'vacation_mode',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function lineOfBusiness(): BelongsTo
    {
        return $this->belongsTo(Category::class, 'line_of_business_category_id');
    }

    public function addresses(): MorphMany
    {
        return $this->morphMany(Address::class, 'addressable');
    }

    protected function casts(): array
    {
        return ['vacation_mode' => 'boolean'];
    }
}
