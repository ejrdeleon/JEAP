@extends('layouts.storefront')

@section('title', 'Your cart | JEAP')
@section('crumb')<span>Your cart</span>@endsection

@section('content')
@php
    $merchandise = $cart->items->sum(fn ($item) => (float) $item->unit_price * $item->quantity);
    $shippingFee = \App\Commerce\InventoryPolicy::shippingFee();
    $maxQty = \App\Commerce\InventoryPolicy::maxQtyPerProduct();
@endphp
<section class="s3-main s3-cart cart-page">
    <div class="cart-items-column" data-cart-items-column>
        <header class="cart-page-heading">
            <div>
                <span class="account-eyebrow">JEAP SHOPPING BAG</span>
                <h1>Your cart</h1>
                <p data-cart-count-heading>{{ $cart->items->count() }} {{ Str::plural('product', $cart->items->count()) }} in your cart</p>
            </div>
            <a href="{{ route('products.index') }}">Continue shopping <span aria-hidden="true">→</span></a>
        </header>
        @if ($errors->any())<div class="s3-alert" role="alert" aria-live="polite">{{ $errors->first() }}</div>@endif
        @if (session('toast'))<div class="cart-toast" role="status">{{ session('toast') }}</div>@endif

        @forelse($cart->items as $item)
            @php
                $product = $item->variant?->product;
                $image = $product?->primaryImage();
                $isAvailable = $item->variant?->is_active && $product?->status === 'active';
                $isSellable = $isAvailable && $item->variant->isSellable();
                $hasStock = $isSellable && $item->variant->stock >= $item->quantity;
                $lineMax = min($maxQty, $item->variant?->stock ?? 0);
            @endphp
            <article class="s3-pcard cart-item" data-cart-item="{{ $item->id }}" data-item-stock="{{ $item->variant?->stock ?? 0 }}">
                @if($image)<img src="{{ asset($image->path) }}" alt="{{ $product->name }}">@else<div class="cart-product-placeholder" aria-hidden="true"><span></span></div>@endif
                <div class="cart-item-details">
                    <h2 class="cart-product-name">@if($product)<a href="{{ route('products.show', $product->slug) }}">{{ $product->name }}</a>@else Unavailable product @endif</h2>
                    @if($item->seller)<p class="cart-seller">Sold by {{ $item->seller->name }}</p>@endif
                    <div class="price">₱{{ number_format((float) $item->unit_price, 2) }} <span>each</span></div>
                    <p class="cart-line-total">Item total <strong data-cart-line-total>₱{{ number_format((float) $item->unit_price * $item->quantity, 2) }}</strong></p>
                    <form method="post" action="{{ route('cart.update', $item) }}" class="s3-qty cart-quantity" data-cart-update-form>
                        @csrf @method('PATCH')
                        <button type="submit" name="quantity" value="{{ max(1, $item->quantity - 1) }}" data-qty-btn="decrease" aria-label="Decrease quantity" @disabled($item->quantity <= 1)>−</button>
                        <input name="qty_display" value="{{ $item->quantity }}" readonly aria-label="Quantity" data-qty-input>
                        <button type="submit" name="quantity" value="{{ $item->quantity + 1 }}" data-qty-btn="increase" aria-label="Increase quantity" @disabled(!$isSellable || $item->quantity >= $lineMax)>+</button>
                    </form>
                    <div data-cart-stock-container>
                        @if(!$isAvailable)<p class="cart-stock is-unavailable">This product is no longer available. Remove it to continue.</p>
                        @elseif(!$isSellable)<p class="cart-stock is-unavailable">This product needs at least {{ \App\Commerce\InventoryPolicy::minSellableStock() }} units in stock before it can be sold.</p>
                        @elseif(!$hasStock)<p class="cart-stock is-unavailable">Only {{ $item->variant->stock }} available. Reduce the quantity to continue.</p>
                        @else<p class="cart-stock">In stock <span aria-hidden="true">·</span> up to {{ $lineMax }} per order</p>@endif
                    </div>
                </div>
                <form method="post" action="{{ route('cart.remove', $item) }}" class="cart-remove-form" data-cart-remove-form>
                    @csrf @method('DELETE')
                    <button class="cart-remove" type="submit" aria-label="Remove {{ $product?->name ?? 'unavailable product' }} from cart">Remove</button>
                </form>
            </article>
        @empty
            <div class="cart-empty"><span class="cart-empty-icon" aria-hidden="true">🛒</span><h2>Your cart is empty</h2><p>Find something you love and it will be waiting here.</p><a href="{{ route('products.index') }}">Browse products</a></div>
        @endforelse
    </div>

    <aside class="s3-summary cart-summary" aria-labelledby="cart-summary-title">
        <span class="account-eyebrow">YOUR ORDER</span><h2 id="cart-summary-title">Summary</h2>
        <div data-cart-summary-container>
            @if($cart->items->isNotEmpty())
                <div class="s3-line"><span data-summary-products-count>{{ $cart->items->count() }} {{ Str::plural('product', $cart->items->count()) }}</span><strong data-summary-total>₱{{ number_format($merchandise, 2) }}</strong></div>
                <div class="s3-line"><span>Shipping</span><strong>₱{{ number_format($shippingFee, 2) }}</strong></div>
                <div class="s3-line cart-total"><strong>Subtotal</strong><strong data-summary-subtotal>₱{{ number_format($merchandise, 2) }}</strong></div>
                <p class="cart-summary-note">Cash on Delivery only. Standard shipping is ₱{{ number_format($shippingFee, 0) }} per seller order. Maximum {{ $maxQty }} units of the same product.</p>
                <div class="s3-checkout-btn" data-checkout-btn-wrapper>
                    @if($canCheckout)<a class="s3-btn" href="{{ route('checkout') }}">Continue to checkout <span aria-hidden="true">→</span></a>
                    @else<p class="cart-checkout-blocked" role="status">Update or remove unavailable items to continue.</p>@endif
                </div>
            @else
                <p class="cart-summary-note">Your order total will appear here when you add products.</p>
            @endif
        </div>
    </aside>
</section>
@endsection
