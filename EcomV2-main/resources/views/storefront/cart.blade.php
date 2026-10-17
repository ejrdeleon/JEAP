@extends('layouts.storefront')

@section('title', 'Card')
@section('crumb')
    <a href="{{ route('about') }}">pages</a>
    <span>/</span>
    <span>cart</span>
@endsection

@section('content')
@php $total = $cart->items->sum(fn ($i) => $i->unit_price * $i->quantity); @endphp
<section class="s3-main s3-cart" data-figma="Card 1:3510">
    <div>
        @if ($errors->any())
            <div class="s3-alert" role="alert" aria-live="polite">{{ $errors->first() }}</div>
        @endif
        @forelse($cart->items as $item)
            @php $product = $item->variant?->product; $img = $product?->primaryImage(); @endphp
            <article class="s3-pcard">
                @if($img)
                    <img src="{{ asset($img->path) }}" alt="{{ $product->name }}">
                @else
                    <img src="{{ asset('images/storefront/login.svg') }}" alt="">
                @endif
                <div>
                    <h6><a href="{{ route('products.show', $product->slug) }}">{{ $product->name }}</a></h6>
                    <div class="price">₱{{ number_format($item->unit_price, 2) }}</div>
                    <form method="post" action="{{ route('cart.update', $item) }}" class="s3-qty" style="margin:16px 0;">
                        @csrf @method('PATCH')
                        <button type="submit" name="quantity" value="{{ max(1, $item->quantity - 1) }}">−</button>
                        <input name="qty_display" value="{{ $item->quantity }}" readonly>
                        <button type="submit" name="quantity" value="{{ $item->quantity + 1 }}">+</button>
                    </form>
                    <span class="s3-chip">free shipping</span>
                    <p class="in-stock">{{ $item->variant && $item->variant->is_active && $product?->status === 'active' && $item->variant->stock >= $item->quantity ? '● In stock' : 'Unavailable or limited stock' }}</p>
                </div>
                <div>
                    <form method="post" action="{{ route('cart.remove', $item) }}">
                        @csrf @method('DELETE')
                        <button type="submit" style="border:0;background:#f3f3f7;width:35px;height:35px;cursor:pointer;">×</button>
                    </form>
                </div>
                @if($item->variant?->compare_at_price)
                    <div class="s3-save">save<br>₱{{ number_format($item->variant->compare_at_price - $item->unit_price, 2) }}</div>
                @endif
            </article>
        @empty
            <p>Your cart is empty. <a href="{{ route('products.index') }}">Continue shopping</a></p>
        @endforelse
    </div>
    <aside class="s3-summary">
        <h3>Order Summary</h3>
        <div class="s3-line"><span>Sub Total:</span><strong>₱{{ number_format($total, 2) }}</strong></div>
        <div class="s3-line"><span>Shipping estimate:</span><strong>₱0.00</strong></div>
        <div class="s3-line"><span>Tax estimate:</span><strong>₱0.00</strong></div>
        <div class="s3-line" style="border:0;"><strong>Order total:</strong><strong>₱{{ number_format($total, 2) }}</strong></div>
        <div class="s3-checkout-btn">
            <a class="s3-btn" href="{{ route('checkout') }}" style="min-width:155px;">checkout</a>
        </div>
    </aside>
</section>
@endsection
