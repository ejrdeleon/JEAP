<?php

namespace App\Http\Controllers\Storefront;

use App\Http\Controllers\Controller;
use App\Models\Announcement;
use App\Models\Category;
use App\Models\Product;
use Illuminate\View\View;

class HomeController extends Controller
{
    public function __invoke(): View
    {
        $categories = Category::query()
            ->where('is_active', true)
            ->parents()
            ->orderBy('sort_order')
            ->get();

        $products = Product::query()
            ->listed()
            ->with([
                'images',
                'variants' => fn ($query) => $query->sellable(),
                'category',
            ])
            ->latest()
            ->take(16)
            ->get();

        $deals = $products->take(7);
        $featured = $products->skip(3)->take(5);
        $audiences = ['all'];
        if (auth()->user()?->hasRole('buyer')) {
            $audiences[] = 'buyers';
        }
        if (auth()->user()?->hasRole('seller')) {
            $audiences[] = 'sellers';
        }
        $announcements = Announcement::query()
            ->where('is_published', true)
            ->whereIn('audience', $audiences)
            ->latest('published_at')
            ->limit(3)
            ->get();

        return view('storefront.home', compact('categories', 'products', 'deals', 'featured', 'announcements'));
    }
}
