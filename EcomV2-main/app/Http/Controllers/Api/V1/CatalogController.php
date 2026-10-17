<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\Product;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CatalogController extends Controller
{
    public function me(Request $request): JsonResponse
    {
        $user = $request->user();

        return response()->json([
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'roles' => $user->getRoleNames()->values(),
        ]);
    }

    public function categories(): JsonResponse
    {
        return response()->json(
            Category::query()
                ->where('is_active', true)
                ->orderBy('sort_order')
                ->get(['id', 'name', 'slug', 'sort_order'])
        );
    }

    public function products(Request $request): JsonResponse
    {
        $query = Product::query()
            ->where('status', 'active')
            ->notOnVacation()
            ->whereHas('variants', fn ($q) => $q->where('is_active', true))
            ->with([
                'variants' => fn ($q) => $q->where('is_active', true)->select([
                    'id', 'product_id', 'sku', 'color', 'size', 'price', 'compare_at_price', 'stock', 'is_active',
                ]),
                'images' => fn ($q) => $q->select(['id', 'product_id', 'path', 'sort_order']),
                'category:id,name,slug',
            ]);

        if ($request->filled('category')) {
            $query->whereHas('category', fn ($q) => $q->where('slug', $request->category));
        }
        if ($request->filled('q')) {
            $query->where('name', 'like', '%'.$request->q.'%');
        }
        if ($request->filled('min_price')) {
            $query->whereHas('variants', fn ($q) => $q->where('price', '>=', $request->min_price));
        }
        if ($request->filled('max_price')) {
            $query->whereHas('variants', fn ($q) => $q->where('price', '<=', $request->max_price));
        }

        return response()->json($query->paginate(20));
    }

    public function product(string $slug): JsonResponse
    {
        $product = Product::query()
            ->where('slug', $slug)
            ->where('status', 'active')
            ->notOnVacation()
            ->with([
                'variants' => fn ($q) => $q->where('is_active', true),
                'images',
                'category:id,name,slug',
                'seller:id,first_name,last_name',
                'seller.sellerProfile:user_id,business_name,logo_path,description',
            ])
            ->firstOrFail();

        return response()->json($product);
    }
}
