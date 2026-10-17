<?php

namespace App\Http\Controllers\Storefront;

use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\View\View;

class ProductController extends Controller
{
    public function index(Request $request): View
    {
        $query = Product::query()
            ->where('status', 'active')
            ->whereHas('variants', fn ($q) => $q->where('is_active', true))
            ->with([
                'images',
                'variants' => fn ($q) => $q->where('is_active', true),
                'category',
            ]);

        if ($request->filled('q')) {
            $query->where('name', 'like', '%'.$request->string('q').'%');
        }

        if ($request->filled('category')) {
            $query->whereHas('category', fn ($q) => $q->where('slug', $request->string('category')));
        }

        $products = $query->paginate(12)->withQueryString();
        $categories = Category::query()->where('is_active', true)->orderBy('sort_order')->get();

        return view('storefront.products', compact('products', 'categories'));
    }

    public function show(string $slug): View
    {
        $product = Product::query()
            ->where('slug', $slug)
            ->where('status', 'active')
            ->whereHas('variants', fn ($q) => $q->where('is_active', true))
            ->with([
                'images',
                'variants' => fn ($q) => $q->where('is_active', true),
                'category',
                'seller.sellerProfile',
            ])
            ->firstOrFail();

        $related = Product::query()
            ->where('status', 'active')
            ->where('category_id', $product->category_id)
            ->where('id', '!=', $product->id)
            ->whereHas('variants', fn ($q) => $q->where('is_active', true))
            ->with(['images', 'variants' => fn ($q) => $q->where('is_active', true)])
            ->take(6)
            ->get();

        return view('storefront.product', compact('product', 'related'));
    }

    public function pay(string $slug): View
    {
        $product = Product::query()
            ->where('slug', $slug)
            ->where('status', 'active')
            ->whereHas('variants', fn ($q) => $q->where('is_active', true))
            ->with([
                'images',
                'variants' => fn ($q) => $q->where('is_active', true),
                'category',
                'seller.sellerProfile',
            ])
            ->firstOrFail();

        $related = Product::query()
            ->where('status', 'active')
            ->where('id', '!=', $product->id)
            ->whereHas('variants', fn ($q) => $q->where('is_active', true))
            ->with(['images', 'variants' => fn ($q) => $q->where('is_active', true)])
            ->take(6)
            ->get();

        $sessionId = session()->getId();
        $cart = \App\Models\Cart::query()
            ->when(auth()->check(), fn ($q) => $q->where('user_id', auth()->id()), fn ($q) => $q->where('session_id', $sessionId))
            ->with(['items.variant.product.images'])
            ->first();

        return view('storefront.product-pay', compact('product', 'related', 'cart'));
    }
}
