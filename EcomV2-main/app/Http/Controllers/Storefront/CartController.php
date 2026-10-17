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
        $cart = $this->cart($request)->load(['items.variant.product.images', 'items.seller.sellerProfile']);

        return view('storefront.cart', compact('cart'));
    }

    public function add(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'product_variant_id' => ['required', 'exists:product_variants,id'],
            'quantity' => ['nullable', 'integer', 'min:1'],
        ]);

        $variant = ProductVariant::query()
            ->whereKey($data['product_variant_id'])
            ->where('is_active', true)
            ->whereHas('product', fn ($query) => $query->where('status', 'active'))
            ->with('product')
            ->firstOrFail();
        $cart = $this->cart($request);
        $qty = $data['quantity'] ?? 1;

        $item = $cart->items()->where('product_variant_id', $variant->id)->first();
        $newQuantity = ($item?->quantity ?? 0) + $qty;

        if ($newQuantity > $variant->stock) {
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

        return back()->with('toast', 'Added to cart');
    }

    public function update(Request $request, CartItem $item): RedirectResponse
    {
        $data = $request->validate([
            'quantity' => ['required', 'integer', 'min:1'],
        ]);

        $cart = $this->cart($request);
        $item->load('variant.product');

        if ($item->cart_id !== $cart->id) {
            abort(404);
        }

        abort_unless($item->variant?->is_active && $item->variant?->product?->status === 'active', 404);
        if ($data['quantity'] > $item->variant->stock) {
            return back()->withErrors(['quantity' => 'The requested quantity is not available.'])->withInput();
        }
        $item->update(['quantity' => $data['quantity'], 'unit_price' => $item->variant->price]);

        return back()->with('toast', 'Cart updated');
    }

    public function remove(Request $request, CartItem $item): RedirectResponse
    {
        $cart = $this->cart($request);

        if ($item->cart_id !== $cart->id) {
            abort(404);
        }
        $item->delete();

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
