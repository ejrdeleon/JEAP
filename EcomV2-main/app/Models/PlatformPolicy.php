<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PlatformPolicy extends Model
{
    protected $fillable = [
        'key',
        'title',
        'body',
    ];
}
