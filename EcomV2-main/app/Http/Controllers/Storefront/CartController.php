<?php

namespace App\Http\Controllers\Storefront;

use App\Commerce\InventoryPolicy;
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
        $canCheckout = $cart->items->isNotEmpty() && $cart->items->every(fn (CartItem $item): bool => $this->itemIsCheckoutReady($item));

        return view('storefront.cart', compact('cart', 'canCheckout'));
    }

    public function add(Request $request): RedirectResponse|\Illuminate\Http\JsonResponse
    {
        $data = $request->validate([
            'product_variant_id' => ['required', 'exists:product_variants,id'],
            'quantity' => ['nullable', 'integer', 'min:1', 'max:'.InventoryPolicy::maxQtyPerProduct()],
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
        $limit = min(InventoryPolicy::maxQtyPerProduct(), $variant->stock);

        if (! InventoryPolicy::isSellable($variant)) {
            return $this->quantityError($request, 'This product needs at least '.InventoryPolicy::minSellableStock().' units in stock before it can be sold.', $variant->stock);
        }

        if ($newQuantity > $limit) {
            return $this->quantityError($request, 'You can add at most '.InventoryPolicy::maxQtyPerProduct().' units of this product.', $limit);
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
            'quantity' => ['required', 'integer', 'min:1', 'max:'.InventoryPolicy::maxQtyPerProduct()],
        ]);

        $cart = $this->cart($request);
        $item->load('variant.product');

        if ($item->cart_id !== $cart->id) {
            abort(404);
        }

        abort_unless($item->variant?->is_active && $item->variant?->product?->status === 'active' && ! $item->variant?->product?->seller?->sellerProfile?->vacation_mode, 404);
        $limit = min(InventoryPolicy::maxQtyPerProduct(), $item->variant->stock);
        if (! InventoryPolicy::isSellable($item->variant) || $data['quantity'] > $limit) {
            return $this->quantityError($request, 'You can keep at most '.InventoryPolicy::maxQtyPerProduct().' units of this product, and stock must be at least '.InventoryPolicy::minSellableStock().'.', $limit);
        }
        $item->update(['quantity' => $data['quantity'], 'unit_price' => $item->variant->price]);

        if ($request->expectsJson() || $request->ajax()) {
            $cart->load(['items.variant.product.images', 'items.seller']);
            $cartTotal = $cart->items->sum(fn ($i) => (float) $i->unit_price * $i->quantity);
            $cartCount = $cart->items->sum('quantity');
            $uniqueCount = $cart->items->count();
            $lineTotal = (float) $item->unit_price * $item->quantity;
            $canCheckout = $cart->items->isNotEmpty() && $cart->items->every(fn (CartItem $i): bool => $this->itemIsCheckoutReady($i));
            $hasStock = InventoryPolicy::isSellable($item->variant) && $item->variant->stock >= $item->quantity;

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
                    'can_increase' => $item->quantity < min(InventoryPolicy::maxQtyPerProduct(), $item->variant->stock),
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
            $canCheckout = $cart->items->isNotEmpty() && $cart->items->every(fn (CartItem $i): bool => $this->itemIsCheckoutReady($i));

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

    private function itemIsCheckoutReady(CartItem $item): bool
    {
        return InventoryPolicy::isSellable($item->variant)
            && $item->variant?->product?->status === 'active'
            && ! $item->variant?->product?->seller?->sellerProfile?->vacation_mode
            && $item->variant->stock >= $item->quantity
            && $item->quantity <= InventoryPolicy::maxQtyPerProduct();
    }

    private function quantityError(Request $request, string $message, int $stock): RedirectResponse|\Illuminate\Http\JsonResponse
    {
        if ($request->expectsJson() || $request->ajax()) {
            return response()->json([
                'success' => false,
                'message' => $message,
                'stock' => $stock,
            ], 422);
        }

        return back()->withErrors(['quantity' => $message])->withInput();
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
