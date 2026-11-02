<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\Product;
use App\Models\SellerProfile;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class CatalogController extends Controller
{
    public function categories(): JsonResponse
    {
        return response()->json(
            Category::query()
                ->where('is_active', true)
                ->parents()
                ->orderBy('sort_order')
                ->with(['children' => fn ($q) => $q->where('is_active', true)->orderBy('sort_order')->select(['id', 'parent_id', 'name', 'slug', 'sort_order'])])
                ->get(['id', 'name', 'slug', 'sort_order'])
        );
    }

    public function products(Request $request): JsonResponse
    {
        if (! $request->filled('q') && $request->filled('search')) {
            $request->merge(['q' => $request->input('search')]);
        }
        $filters = $request->validate([
            'q' => ['nullable', 'string', 'max:120'],
            'search' => ['nullable', 'string', 'max:120'],
            'category' => ['nullable', 'string', 'max:120'],
            'category_id' => ['nullable', 'integer'],
            'brand' => ['nullable', 'string', 'max:120'],
            'min_price' => ['nullable', 'numeric', 'min:0', 'max:999999999'],
            'max_price' => ['nullable', 'numeric', 'min:0', 'max:999999999', Rule::when($request->filled('min_price'), 'gte:min_price')],
            'sort' => ['nullable', 'in:relevance,price_asc,price_desc,newest'],
            'in_stock' => ['nullable', 'boolean'],
        ]);

        $query = Product::query()
            ->listed()
            ->with([
                'category:id,name,slug,parent_id',
                'variants' => fn ($q) => $q->sellable()->select([
                    'id', 'product_id', 'sku', 'color', 'size', 'price', 'compare_at_price', 'stock', 'is_active',
                ]),
                'images' => fn ($q) => $q->select(['id', 'product_id', 'path', 'sort_order']),
            ]);

        $search = trim((string) ($filters['q'] ?? $filters['brand'] ?? ''));
        if ($search !== '') {
            $term = addcslashes($search, '%_\\');
            $query->where(fn ($q) => $q->where('name', 'like', '%'.$term.'%')
                ->orWhere('description', 'like', '%'.$term.'%'));
        }

        if (! empty($filters['category'])) {
            $query->whereHas('category', function ($q) use ($filters): void {
                $q->where('slug', $filters['category'])
                    ->orWhereHas('parent', fn ($parent) => $parent->where('slug', $filters['category']));
            });
        }

        if (! empty($filters['category_id'])) {
            $categoryId = (int) $filters['category_id'];
            $query->where(function ($q) use ($categoryId): void {
                $q->where('category_id', $categoryId)
                    ->orWhereHas('category', fn ($category) => $category->where('parent_id', $categoryId));
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

        return response()->json($query->paginate(20)->withQueryString());
    }

    public function show(string $slug): JsonResponse
    {
        $product = Product::query()
            ->listed()
            ->where(function ($q) use ($slug): void {
                $q->where('slug', $slug);
                if (ctype_digit($slug)) {
                    $q->orWhere('id', (int) $slug);
                }
            })
            ->with([
                'category:id,name,slug,parent_id',
                'variants' => fn ($q) => $q->sellable()->select([
                    'id', 'product_id', 'sku', 'color', 'size', 'price', 'compare_at_price', 'stock', 'is_active',
                ]),
                'images' => fn ($q) => $q->select(['id', 'product_id', 'path', 'sort_order']),
            ])
            ->firstOrFail();

        return response()->json(['product' => $product]);
    }

    public function brands(): JsonResponse
    {
        $brands = SellerProfile::query()
            ->whereHas('user.products', fn ($q) => $q->listed())
            ->orderBy('business_name')
            ->get(['id', 'business_name'])
            ->map(fn (SellerProfile $profile) => [
                'id' => $profile->id,
                'name' => $profile->business_name,
                'slug' => Str::slug($profile->business_name),
            ])
            ->values();

        return response()->json(['data' => $brands]);
    }

    public function home(): JsonResponse
    {
        $with = [
            'category:id,name,slug,parent_id',
            'variants' => fn ($q) => $q->sellable()->select([
                'id', 'product_id', 'sku', 'color', 'size', 'price', 'compare_at_price', 'stock', 'is_active',
            ]),
            'images' => fn ($q) => $q->select(['id', 'product_id', 'path', 'sort_order']),
        ];

        return response()->json([
            'featured' => Product::query()->listed()->where('is_featured', true)->with($with)->latest()->limit(8)->get(),
            'new_arrivals' => Product::query()->listed()->with($with)->latest()->limit(12)->get(),
            'categories' => Category::query()
                ->where('is_active', true)
                ->parents()
                ->orderBy('sort_order')
                ->get(['id', 'name', 'slug', 'sort_order']),
        ]);
    }

    public function sellerProducts(Request $request): JsonResponse
    {
        $products = Product::query()
            ->where('seller_id', $request->user()->id)
            ->with([
                'category:id,name,slug,parent_id',
                'variants' => fn ($q) => $q->select([
                    'id', 'product_id', 'sku', 'color', 'size', 'price', 'compare_at_price', 'stock', 'is_active',
                ]),
                'images' => fn ($q) => $q->select(['id', 'product_id', 'path', 'sort_order']),
            ])
            ->latest()
            ->get();

        return response()->json(['products' => $products]);
    }
}
