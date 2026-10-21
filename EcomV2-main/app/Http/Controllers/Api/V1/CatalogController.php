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
                ->parents()
                ->orderBy('sort_order')
                ->with(['children' => fn ($q) => $q->where('is_active', true)->orderBy('sort_order')->select(['id', 'parent_id', 'name', 'slug', 'sort_order'])])
                ->get(['id', 'name', 'slug', 'sort_order'])
        );
    }

    public function products(): JsonResponse
    {
        return response()->json(
            Product::query()
                ->listed()
                ->with([
                    'variants' => fn ($q) => $q->sellable()->select([
                        'id', 'product_id', 'sku', 'color', 'size', 'price', 'compare_at_price', 'stock', 'is_active',
                    ]),
                    'images' => fn ($q) => $q->select(['id', 'product_id', 'path', 'sort_order']),
                ])
                ->paginate(20)
        );
    }
}
