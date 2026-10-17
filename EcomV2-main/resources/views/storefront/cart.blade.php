@extends('layouts.storefront')

@section('title', 'Your cart | JEAP')
@section('crumb')<span>Your cart</span>@endsection

@section('content')
@php $total = $cart->items->sum(fn ($item) => (float) $item->unit_price * $item->quantity); @endphp
<section class="s3-main s3-cart cart-page" data-figma="Card 1:3510">
    <div class="cart-items-column">
        <header class="cart-page-heading">
            <div><span class="account-eyebrow">JEAP SHOPPING BAG</span><h1>Your cart</h1><p>{{ $cart->items->count() }} {{ Str::plural('product', $cart->items->count()) }} in your cart</p></div>
            <a href="{{ route('products.index') }}">Continue shopping <span aria-hidden="true">→</span></a>
        </header>
        @if ($errors->any())<div class="s3-alert" role="alert" aria-live="polite">{{ $errors->first() }}</div>@endif
        @if (session('toast'))<div class="cart-toast" role="status">{{ session('toast') }}</div>@endif

        @forelse($cart->items as $item)
            @php
                $product = $item->variant?->product;
                $image = $product?->primaryImage();
                $isAvailable = $item->variant?->is_active && $product?->status === 'active';
                $hasStock = $isAvailable && $item->variant->stock >= $item->quantity;
            @endphp
            <article class="s3-pcard cart-item">
                @if($image)<img src="{{ asset($image->path) }}" alt="{{ $product->name }}">@else<div class="cart-product-placeholder" aria-hidden="true"><span></span></div>@endif
                <div class="cart-item-details">
                    <h2 class="cart-product-name">@if($product)<a href="{{ route('products.show', $product->slug) }}">{{ $product->name }}</a>@else Unavailable product @endif</h2>
                    @if($item->seller)<p class="cart-seller">Sold by {{ $item->seller->name }}</p>@endif
                    <div class="price">₱{{ number_format((float) $item->unit_price, 2) }} <span>each</span></div>
                    <p class="cart-line-total">Item total <strong>₱{{ number_format((float) $item->unit_price * $item->quantity, 2) }}</strong></p>
                    <form method="post" action="{{ route('cart.update', $item) }}" class="s3-qty cart-quantity">
                        @csrf @method('PATCH')
                        <button type="submit" name="quantity" value="{{ max(1, $item->quantity - 1) }}" aria-label="Decrease quantity">−</button>
                        <input name="qty_display" value="{{ $item->quantity }}" readonly aria-label="Quantity">
                        <button type="submit" name="quantity" value="{{ $item->quantity + 1 }}" aria-label="Increase quantity">+</button>
                    </form>
                    @if(!$isAvailable)<p class="cart-stock is-unavailable">This product is no longer available. Remove it to continue.</p>
                    @elseif(!$hasStock)<p class="cart-stock is-unavailable">Only {{ $item->variant->stock }} available. Reduce the quantity to continue.</p>
                    @else<p class="cart-stock">In stock <span aria-hidden="true">·</span> {{ $item->variant->stock }} available</p>@endif
                </div>
                <form method="post" action="{{ route('cart.remove', $item) }}" class="cart-remove-form">
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
        @if($cart->items->isNotEmpty())
            <div class="s3-line"><span>{{ $cart->items->count() }} {{ Str::plural('product', $cart->items->count()) }}</span><strong>₱{{ number_format($total, 2) }}</strong></div>
            <div class="s3-line cart-total"><strong>Subtotal</strong><strong>₱{{ number_format($total, 2) }}</strong></div>
            <p class="cart-summary-note">Cash on Delivery is available. Delivery details are confirmed during checkout.</p>
            <div class="s3-checkout-btn">
                @if($canCheckout)<a class="s3-btn" href="{{ route('checkout') }}">Continue to checkout <span aria-hidden="true">→</span></a>
                @else<p class="cart-checkout-blocked" role="status">Update or remove unavailable items to continue.</p>@endif
            </div>
        @else
            <p class="cart-summary-note">Your order total will appear here when you add products.</p>
        @endif
    </aside>
</section>
@endsection
