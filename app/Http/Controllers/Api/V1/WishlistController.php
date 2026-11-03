<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Product;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class WishlistController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $products = $request->user()->wishlistProducts()
            ->where('status', 'active')
            ->with([
                'category:id,name,slug,parent_id',
                'variants' => fn ($q) => $q->sellable()->select([
                    'id', 'product_id', 'sku', 'color', 'size', 'price', 'compare_at_price', 'stock', 'is_active',
                ]),
                'images' => fn ($q) => $q->select(['id', 'product_id', 'path', 'sort_order']),
            ])
            ->latest('buyer_wishlists.created_at')
            ->get();

        return response()->json(['data' => $products]);
    }

    public function store(Request $request, Product $product): JsonResponse
    {
        abort_unless($product->status === 'active' && $product->variants()->where('is_active', true)->exists(), 404);
        $request->user()->wishlistProducts()->syncWithoutDetaching([$product->id]);

        return response()->json(['message' => 'Product saved to your wishlist.']);
    }

    public function destroy(Request $request, Product $product): JsonResponse
    {
        $request->user()->wishlistProducts()->detach($product->id);

        return response()->json(['message' => 'Product removed from your wishlist.']);
    }
}
