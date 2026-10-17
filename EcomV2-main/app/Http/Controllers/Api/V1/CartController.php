<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Cart;
use App\Models\CartItem;
use App\Models\ProductVariant;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CartController extends Controller
{
    private function getOrCreateCart(Request $request): Cart
    {
        return Cart::firstOrCreate(['user_id' => $request->user()->id]);
    }

    public function show(Request $request): JsonResponse
    {
        $cart = $this->getOrCreateCart($request);

        $items = $cart->items()->with([
            'variant.product.images',
            'variant.product.category',
            'seller:id,first_name,last_name',
        ])->get()->map(fn ($item) => $this->itemPayload($item));

        return response()->json(['items' => $items]);
    }

    public function add(Request $request): JsonResponse
    {
        $data = $request->validate([
            'product_variant_id' => ['required', 'integer', 'exists:product_variants,id'],
            'quantity'           => ['required', 'integer', 'min:1'],
        ]);

        $variant = ProductVariant::query()->whereKey($data['product_variant_id'])
            ->where('is_active', true)
            ->whereHas('product', fn ($query) => $query->where('status', 'active'))
            ->with('product')
            ->firstOrFail();

        if ($variant->stock < $data['quantity']) {
            return response()->json(['message' => 'Not enough stock.'], 422);
        }

        $cart = $this->getOrCreateCart($request);

        $item = $cart->items()->where('product_variant_id', $variant->id)->first();
        $newQuantity = ($item?->quantity ?? 0) + $data['quantity'];

        if ($variant->stock < $newQuantity) {
            return response()->json(['message' => 'Not enough stock.'], 422);
        }

        if ($item) {
            $item->update(['quantity' => $newQuantity, 'unit_price' => $variant->price]);
        } else {
            $cart->items()->create([
                'seller_id'          => $variant->product->seller_id,
                'product_variant_id' => $variant->id,
                'quantity'           => $data['quantity'],
                'unit_price'         => $variant->price,
            ]);
        }

        return response()->json(['message' => 'Item added to cart.']);
    }

    public function update(Request $request, int $itemId): JsonResponse
    {
        $data = $request->validate([
            'quantity' => ['required', 'integer', 'min:1'],
        ]);

        $cart = $this->getOrCreateCart($request);
        $item = $cart->items()->findOrFail($itemId);
        $item->load('variant.product');
        if (! $item->variant?->is_active || $item->variant?->product?->status !== 'active') {
            return response()->json(['message' => 'This product is no longer available.'], 422);
        }
        if ($item->variant->stock < $data['quantity']) {
            return response()->json(['message' => 'Not enough stock.'], 422);
        }
        $item->update(['quantity' => $data['quantity'], 'unit_price' => $item->variant->price]);

        return response()->json(['message' => 'Cart updated.']);
    }

    public function remove(Request $request, int $itemId): JsonResponse
    {
        $cart = $this->getOrCreateCart($request);
        $cart->items()->findOrFail($itemId)->delete();

        return response()->json(['message' => 'Item removed.']);
    }

    private function itemPayload(CartItem $item): array
    {
        $variant = $item->variant;
        $product = $variant?->product;

        return [
            'id'           => $item->id,
            'product_id'   => $product?->id,
            'product_name' => $product?->name,
            'variant_id'   => $variant?->id,
            'color'        => $variant?->color,
            'size'         => $variant?->size,
            'sku'          => $variant?->sku,
            'price'        => (float) $item->unit_price,
            'quantity'     => $item->quantity,
            'subtotal'     => round((float) $item->unit_price * $item->quantity, 2),
            'image_url'    => $product?->images->first()?->path
                ? asset('storage/' . $product->images->first()->path)
                : null,
            'seller_name'  => $item->seller
                ? trim($item->seller->first_name . ' ' . $item->seller->last_name)
                : null,
        ];
    }
}
