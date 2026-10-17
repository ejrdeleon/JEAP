<?php

namespace App\Http\Controllers\Storefront;

use App\Http\Controllers\Controller;
use App\Models\Cart;
use App\Models\CartItem;
use App\Models\ProductVariant;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\View\View;

class CartController extends Controller
{
    public function index(Request $request): View
    {
        $cart = $this->cart($request)->load(['items.variant.product.images', 'items.seller']);
        $canCheckout = $cart->items->isNotEmpty() && $cart->items->every(fn (CartItem $item): bool => $item->variant?->is_active
            && $item->variant?->product?->status === 'active'
            && ! $item->variant?->product?->seller?->sellerProfile?->vacation_mode
            && $item->variant->stock >= $item->quantity
        );

        return view('storefront.cart', compact('cart', 'canCheckout'));
    }

    public function add(Request $request): RedirectResponse|\Illuminate\Http\JsonResponse
    {
        $data = $request->validate([
            'product_variant_id' => ['required', 'exists:product_variants,id'],
            'quantity' => ['nullable', 'integer', 'min:1'],
        ]);

        $variant = ProductVariant::query()
            ->whereKey($data['product_variant_id'])
            ->where('is_active', true)
            ->whereHas('product', fn ($query) => $query->where('status', 'active')->notOnVacation())
            ->with('product')
            ->firstOrFail();
        $cart = $this->cart($request);
        $qty = $data['quantity'] ?? 1;

        $item = $cart->items()->where('product_variant_id', $variant->id)->first();
        $newQuantity = ($item?->quantity ?? 0) + $qty;

        if ($newQuantity > $variant->stock) {
            if ($request->expectsJson() || $request->ajax()) {
                return response()->json([
                    'success' => false,
                    'message' => 'The requested quantity is not available.',
                    'stock' => $variant->stock,
                ], 422);
            }
            return back()->withErrors(['quantity' => 'The requested quantity is not available.'])->withInput();
        }

        if ($item) {
            $item->update(['quantity' => $newQuantity, 'unit_price' => $variant->price]);
        } else {
            CartItem::create([
                'cart_id' => $cart->id,
                'seller_id' => $variant->product->seller_id,
                'product_variant_id' => $variant->id,
                'quantity' => $qty,
                'unit_price' => $variant->price,
            ]);
        }

        if ($request->expectsJson() || $request->ajax()) {
            $cart->load('items');
            return response()->json([
                'success' => true,
                'message' => 'Added to cart',
                'cart_count' => $cart->items->sum('quantity'),
                'item_quantity' => $newQuantity,
            ]);
        }

        return back()->with('toast', 'Added to cart');
    }

    public function update(Request $request, CartItem $item): RedirectResponse|\Illuminate\Http\JsonResponse
    {
        $data = $request->validate([
            'quantity' => ['required', 'integer', 'min:1'],
        ]);

        $cart = $this->cart($request);
        $item->load('variant.product');

        if ($item->cart_id !== $cart->id) {
            abort(404);
        }

        abort_unless($item->variant?->is_active && $item->variant?->product?->status === 'active' && ! $item->variant?->product?->seller?->sellerProfile?->vacation_mode, 404);
        if ($data['quantity'] > $item->variant->stock) {
            if ($request->expectsJson() || $request->ajax()) {
                return response()->json([
                    'success' => false,
                    'message' => 'The requested quantity is not available.',
                    'stock' => $item->variant->stock,
                ], 422);
            }
            return back()->withErrors(['quantity' => 'The requested quantity is not available.'])->withInput();
        }
        $item->update(['quantity' => $data['quantity'], 'unit_price' => $item->variant->price]);

        if ($request->expectsJson() || $request->ajax()) {
            $cart->load(['items.variant.product.images', 'items.seller']);
            $cartTotal = $cart->items->sum(fn ($i) => (float) $i->unit_price * $i->quantity);
            $cartCount = $cart->items->sum('quantity');
            $uniqueCount = $cart->items->count();
            $lineTotal = (float) $item->unit_price * $item->quantity;
            $canCheckout = $cart->items->isNotEmpty() && $cart->items->every(fn (CartItem $i): bool => $i->variant?->is_active
                && $i->variant?->product?->status === 'active'
                && ! $i->variant?->product?->seller?->sellerProfile?->vacation_mode
                && $i->variant->stock >= $i->quantity
            );
            $hasStock = $item->variant->stock >= $item->quantity;

            return response()->json([
                'success' => true,
                'message' => 'Cart updated',
                'item' => [
                    'id' => $item->id,
                    'quantity' => $item->quantity,
                    'unit_price' => (float) $item->unit_price,
                    'unit_price_formatted' => '₱' . number_format((float) $item->unit_price, 2),
                    'line_total' => $lineTotal,
                    'line_total_formatted' => '₱' . number_format($lineTotal, 2),
                    'stock' => $item->variant->stock,
                    'has_stock' => $hasStock,
                    'can_increase' => $item->quantity < $item->variant->stock,
                    'can_decrease' => $item->quantity > 1,
                ],
                'cart' => [
                    'total' => $cartTotal,
                    'total_formatted' => '₱' . number_format($cartTotal, 2),
                    'total_items_count' => $cartCount,
                    'unique_products_count' => $uniqueCount,
                    'products_label' => $uniqueCount . ' ' . \Illuminate\Support\Str::plural('product', $uniqueCount),
                    'can_checkout' => $canCheckout,
                ],
            ]);
        }

        return back()->with('toast', 'Cart updated');
    }

    public function remove(Request $request, CartItem $item): RedirectResponse|\Illuminate\Http\JsonResponse
    {
        $cart = $this->cart($request);

        if ($item->cart_id !== $cart->id) {
            abort(404);
        }
        $item->delete();

        if ($request->expectsJson() || $request->ajax()) {
            $cart->load(['items.variant.product', 'items.seller']);
            $cartTotal = $cart->items->sum(fn ($i) => (float) $i->unit_price * $i->quantity);
            $cartCount = $cart->items->sum('quantity');
            $uniqueCount = $cart->items->count();
            $canCheckout = $cart->items->isNotEmpty() && $cart->items->every(fn (CartItem $i): bool => $i->variant?->is_active
                && $i->variant?->product?->status === 'active'
                && ! $i->variant?->product?->seller?->sellerProfile?->vacation_mode
                && $i->variant->stock >= $i->quantity
            );

            return response()->json([
                'success' => true,
                'message' => 'Removed from cart',
                'removed_id' => $item->id,
                'cart' => [
                    'total' => $cartTotal,
                    'total_formatted' => '₱' . number_format($cartTotal, 2),
                    'total_items_count' => $cartCount,
                    'unique_products_count' => $uniqueCount,
                    'products_label' => $uniqueCount . ' ' . \Illuminate\Support\Str::plural('product', $uniqueCount),
                    'can_checkout' => $canCheckout,
                    'is_empty' => $cart->items->isEmpty(),
                ],
            ]);
        }

        return back()->with('toast', 'Removed from cart');
    }

    private function cart(Request $request): Cart
    {
        $sessionId = $request->session()->getId();

        return Cart::firstOrCreate(
            Auth::check()
                ? ['user_id' => Auth::id()]
                : ['session_id' => $sessionId],
            Auth::check()
                ? ['session_id' => $sessionId]
                : ['user_id' => null],
        );
    }
}
