<?php

namespace App\Http\Controllers\Storefront;

use App\Http\Controllers\Controller;
use App\Models\PlatformPolicy;
use Illuminate\View\View;

class PolicyController extends Controller
{
    public function show(string $key): View
    {
        $policy = PlatformPolicy::query()->where('key', $key)->firstOrFail();

        return view('storefront.policy', compact('policy'));
    }
}
