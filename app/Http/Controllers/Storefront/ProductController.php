<?php

namespace App\Http\Controllers\Storefront;

use App\Commerce\CatalogSearch;
use App\Enums\OrderStatus;
use App\Http\Controllers\Controller;
use App\Models\Cart;
use App\Models\CartItem;
use App\Models\Category;
use App\Models\Order;
use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use Illuminate\View\View;

class ProductController extends Controller
{
    public function index(Request $request): View
    {
        $filters = $request->validate([
            'q' => ['nullable', 'string', 'max:120'],
            'category' => ['nullable', 'string', 'max:120'],
            'min_price' => ['nullable', 'numeric', 'min:0', 'max:999999999'],
            'max_price' => ['nullable', 'numeric', 'min:0', 'max:999999999', 'gte:min_price'],
            'sort' => ['nullable', 'in:relevance,price_asc,price_desc,newest'],
            'in_stock' => ['nullable', 'boolean'],
        ]);
        $query = Product::query()
            ->listed()
            ->with([
                'images',
                'variants' => fn ($q) => $q->sellable(),
                'category',
            ])
            ->withAvg('reviews', 'rating')
            ->withCount('reviews');

        $shops = collect();
        if (! empty($filters['q'])) {
            CatalogSearch::applyToProducts($query, $filters['q']);
            $shops = CatalogSearch::shops($filters['q']);
        }

        if (! empty($filters['category'])) {
            $query->whereHas('category', function ($q) use ($filters): void {
                $q->where('slug', $filters['category'])
                    ->orWhereHas('parent', fn ($parent) => $parent->where('slug', $filters['category']));
            });
        }

        if (isset($filters['min_price']) || isset($filters['max_price']) || ! empty($filters['in_stock'])) {
            $query->whereHas('variants', function ($variants) use ($filters): void {
                $variants->sellable()
                    ->when(isset($filters['min_price']), fn ($q) => $q->where('price', '>=', $filters['min_price']))
                    ->when(isset($filters['max_price']), fn ($q) => $q->where('price', '<=', $filters['max_price']));
            });
        }

        match ($filters['sort'] ?? 'relevance') {
            'price_asc' => $query->withMin(['variants' => fn ($q) => $q->sellable()], 'price')->orderBy('variants_min_price'),
            'price_desc' => $query->withMax(['variants' => fn ($q) => $q->sellable()], 'price')->orderByDesc('variants_max_price'),
            default => $query->latest('products.created_at'),
        };

        if (($filters['sort'] ?? null) === 'newest') {
            $query->latest('products.created_at');
        }

        $products = $query->paginate(12)->withQueryString();
        $categories = Category::query()->where('is_active', true)->parents()->orderBy('sort_order')->with('children')->get();

        return view('storefront.products', compact('products', 'categories', 'shops'));
    }

    public function show(Request $request, string $slug): View
    {
        $product = Product::query()
            ->notOnVacation()
            ->where('slug', $slug)
            ->where('status', 'active')
            ->whereHas('variants', fn ($q) => $q->where('is_active', true))
            ->with([
                'images',
                'variants' => fn ($q) => $q->where('is_active', true),
                'category',
                'seller.sellerProfile',
                'reviews' => fn ($q) => $q->latest(),
                'reviews.buyer',
            ])
            ->withAvg('reviews', 'rating')
            ->withCount('reviews')
            ->firstOrFail();

        $related = $this->relatedProducts($product, 8);
        $fromStore = $product->seller_id
            ? Product::query()
                ->listed()
                ->where('seller_id', $product->seller_id)
                ->where('id', '!=', $product->id)
                ->with(['images', 'variants' => fn ($q) => $q->sellable()])
                ->withAvg('reviews', 'rating')
                ->withCount('reviews')
                ->latest()
                ->take(8)
                ->get()
            : collect();

        $variant = $product->defaultVariant();
        $cartQuantity = $variant ? $this->cartQuantity($request, $variant->id) : 0;

        $isWishlisted = auth()->check() && auth()->user()->wishlistProducts()->whereKey($product->id)->exists();
        $isFollowingSeller = auth()->check() && auth()->user()->followedSellers()->whereKey($product->seller_id)->exists();
        $reviewOrder = null;
        $existingReview = null;
        if (auth()->check()) {
            $existingReview = $product->reviews->firstWhere('buyer_id', auth()->id());
            $reviewOrder = Order::query()
                ->where('buyer_id', auth()->id())
                ->where('status', OrderStatus::Completed)
                ->whereHas('items', fn ($items) => $items->where('product_id', $product->id))
                ->latest('id')
                ->first();
            if ($reviewOrder) {
                $existingReview = $product->reviews->firstWhere('order_id', $reviewOrder->id)
                    ?? $existingReview;
            }
        }

        return view('storefront.product', compact(
            'product',
            'related',
            'fromStore',
            'cartQuantity',
            'isWishlisted',
            'isFollowingSeller',
            'reviewOrder',
            'existingReview',
        ));
    }

    public function pay(Request $request, string $slug): View
    {
        return $this->show($request, $slug);
    }

    private function relatedProducts(Product $product, int $limit): Collection
    {
        $related = Product::query()
            ->listed()
            ->where('id', '!=', $product->id)
            ->when($product->category_id, fn ($q) => $q->where('category_id', $product->category_id))
            ->with(['images', 'variants' => fn ($q) => $q->sellable()])
            ->withAvg('reviews', 'rating')
            ->withCount('reviews')
            ->latest()
            ->take($limit)
            ->get();

        if ($related->count() >= $limit) {
            return $related;
        }

        $filler = Product::query()
            ->listed()
            ->where('id', '!=', $product->id)
            ->whereNotIn('id', $related->modelKeys())
            ->with(['images', 'variants' => fn ($q) => $q->sellable()])
            ->withAvg('reviews', 'rating')
            ->withCount('reviews')
            ->latest()
            ->take($limit - $related->count())
            ->get();

        return $related->concat($filler)->values();
    }

    private function cartQuantity(Request $request, int $variantId): int
    {
        $cartId = Cart::query()
            ->when(auth()->check(), fn ($query) => $query->where('user_id', auth()->id()), fn ($query) => $query->where('session_id', $request->session()->getId()))
            ->value('id');

        if (! $cartId) {
            return 0;
        }

        return (int) (CartItem::query()
            ->where('cart_id', $cartId)
            ->where('product_variant_id', $variantId)
            ->value('quantity') ?? 0);
    }
}
