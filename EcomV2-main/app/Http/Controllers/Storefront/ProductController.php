<?php

namespace App\Http\Controllers\Storefront;

use App\Http\Controllers\Controller;
use App\Models\Cart;
use App\Models\CartItem;
use App\Models\Category;
use App\Models\Product;
use Illuminate\Http\Request;
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
            ->notOnVacation()
            ->where('status', 'active')
            ->whereHas('variants', fn ($q) => $q->where('is_active', true))
            ->with([
                'images',
                'variants' => fn ($q) => $q->where('is_active', true),
                'category',
            ]);

        if (! empty($filters['q'])) {
            $term = addcslashes($filters['q'], '%_\\');
            $query->where(fn ($q) => $q->where('name', 'like', '%'.$term.'%')
                ->orWhere('description', 'like', '%'.$term.'%'));
        }

        if (! empty($filters['category'])) {
            $query->whereHas('category', fn ($q) => $q->where('slug', $filters['category']));
        }

        if (isset($filters['min_price']) || isset($filters['max_price']) || ! empty($filters['in_stock'])) {
            $query->whereHas('variants', function ($variants) use ($filters): void {
                $variants->where('is_active', true)
                    ->when(isset($filters['min_price']), fn ($q) => $q->where('price', '>=', $filters['min_price']))
                    ->when(isset($filters['max_price']), fn ($q) => $q->where('price', '<=', $filters['max_price']))
                    ->when(! empty($filters['in_stock']), fn ($q) => $q->where('stock', '>', 0));
            });
        }

        match ($filters['sort'] ?? 'relevance') {
            'price_asc' => $query->withMin(['variants' => fn ($q) => $q->where('is_active', true)], 'price')->orderBy('variants_min_price'),
            'price_desc' => $query->withMax(['variants' => fn ($q) => $q->where('is_active', true)], 'price')->orderByDesc('variants_max_price'),
            default => $query->latest('products.created_at'),
        };

        if (($filters['sort'] ?? null) === 'newest') {
            $query->latest('products.created_at');
        }

        $products = $query->paginate(12)->withQueryString();
        $categories = Category::query()->where('is_active', true)->orderBy('sort_order')->get();

        return view('storefront.products', compact('products', 'categories'));
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
            ])
            ->firstOrFail();

        $related = Product::query()
            ->notOnVacation()
            ->where('status', 'active')
            ->where('category_id', $product->category_id)
            ->where('id', '!=', $product->id)
            ->whereHas('variants', fn ($q) => $q->where('is_active', true))
            ->with(['images', 'variants' => fn ($q) => $q->where('is_active', true)])
            ->take(6)
            ->get();

        $variant = $product->defaultVariant();
        $cartQuantity = $variant ? $this->cartQuantity($request, $variant->id) : 0;

        $isWishlisted = auth()->check() && auth()->user()->wishlistProducts()->whereKey($product->id)->exists();
        $isFollowingSeller = auth()->check() && auth()->user()->followedSellers()->whereKey($product->seller_id)->exists();

        return view('storefront.product', compact('product', 'related', 'cartQuantity', 'isWishlisted', 'isFollowingSeller'));
    }

    public function pay(string $slug): View
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
            ])
            ->firstOrFail();

        $related = Product::query()
            ->notOnVacation()
            ->where('status', 'active')
            ->where('id', '!=', $product->id)
            ->whereHas('variants', fn ($q) => $q->where('is_active', true))
            ->with(['images', 'variants' => fn ($q) => $q->where('is_active', true)])
            ->take(6)
            ->get();

        $sessionId = session()->getId();
        $cart = Cart::query()
            ->when(auth()->check(), fn ($q) => $q->where('user_id', auth()->id()), fn ($q) => $q->where('session_id', $sessionId))
            ->with(['items.variant.product.images'])
            ->first();
        $cartQuantity = $cart?->items
            ->firstWhere('product_variant_id', $product->defaultVariant()?->id)
            ?->quantity ?? 0;

        return view('storefront.product-pay', compact('product', 'related', 'cart', 'cartQuantity'));
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
