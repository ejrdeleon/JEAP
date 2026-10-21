<?php

namespace App\Http\Controllers\Storefront;

use App\Enums\UserStatus;
use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\Product;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\View\View;

class StoreController extends Controller
{
    public function show(Request $request, User $seller): View
    {
        abort_unless($seller->hasRole('seller') && $seller->status === UserStatus::Active, 404);
        $filters = $request->validate([
            'q' => ['nullable', 'string', 'max:120'],
            'category' => ['nullable', 'string', 'max:120'],
            'sort' => ['nullable', 'in:newest,price_asc,price_desc'],
        ]);
        $productsQuery = Product::query()->where('seller_id', $seller->id)
            ->listed()
            ->with(['images', 'variants' => fn ($query) => $query->sellable(), 'category']);

        if (! empty($filters['q'])) {
            $term = addcslashes($filters['q'], '%_\\');
            $productsQuery->where('name', 'like', '%'.$term.'%');
        }
        if (! empty($filters['category'])) {
            $productsQuery->whereHas('category', fn ($query) => $query->where('slug', $filters['category']));
        }
        match ($filters['sort'] ?? 'newest') {
            'price_asc' => $productsQuery->withMin(['variants' => fn ($query) => $query->where('is_active', true)], 'price')->orderBy('variants_min_price'),
            'price_desc' => $productsQuery->withMax(['variants' => fn ($query) => $query->where('is_active', true)], 'price')->orderByDesc('variants_max_price'),
            default => $productsQuery->latest('products.created_at'),
        };
        $products = $productsQuery->paginate(12)->withQueryString();
        $categories = Category::query()->where('is_active', true)
            ->whereHas('products', fn ($query) => $query->where('seller_id', $seller->id)->where('status', 'active'))
            ->orderBy('sort_order')->get();
        $seller->load(['sellerProfile.lineOfBusiness']);

        return view('storefront.store', compact('seller', 'products', 'categories'));
    }
}
