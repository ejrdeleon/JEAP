@extends('layouts.storefront')

@section('title', 'Single Product pay')
@section('crumb')
    <a href="{{ route('products.index') }}">Shop</a>
    <span>/</span>
    <a href="{{ route('products.index', ['category' => $product->category?->slug]) }}">{{ $product->category?->name ?? 'Shop' }}</a>
    <span>/</span>
    <span>{{ $product->name }}</span>
@endsection

@section('content')
@php
    $variant = $product->defaultVariant();
    $images = $product->images;
    $main = $product->primaryImage();
    $cartItems = $cart?->items ?? collect();
    $cartTotal = $cartItems->sum(fn ($i) => $i->unit_price * $i->quantity);
@endphp
<section class="s3-main">
    <div class="s3-pdp">
        <div class="s3-gallery">
            <div class="s3-gallery-main">
                @if($main)
                    <img src="{{ asset($main->path) }}" alt="{{ $product->name }}">
                @endif
                <span class="s3-new">new</span>
            </div>
            <div class="s3-thumbs">
                @foreach($images as $image)
                    <img src="{{ asset($image->path) }}" alt="">
                @endforeach
            </div>
        </div>
        <div>
            <h1>{{ $product->name }}</h1>
            <div class="pdp-price">₱{{ number_format($variant?->price ?? 0, 2) }}</div>
            @if($product->description)
                <p class="s3-bullets">{{ $product->description }}</p>
            @endif
            <span class="s3-chip">₱{{ number_format(\App\Commerce\InventoryPolicy::shippingFee(), 0) }} shipping · COD</span>
            @php
                $canBuy = $variant?->isSellable();
                $maxQty = $variant ? min(\App\Commerce\InventoryPolicy::maxQtyPerProduct(), $variant->stock) : 1;
            @endphp
            <p class="in-stock">{{ $canBuy ? '● In stock' : 'Not available to sell yet' }}</p>
            <p><strong>qty</strong></p>
            <form method="post" action="{{ route('cart.add') }}" style="display:flex;flex-wrap:wrap;gap:16px;align-items:center;" data-cart-add-form data-existing-quantity="{{ $cartQuantity }}">
                @csrf
                <input type="hidden" name="product_variant_id" value="{{ $variant?->id }}">
                <div class="s3-qty" data-quantity-control style="height:53px;">
                    <button type="button" data-quantity-decrease aria-label="Decrease quantity" @disabled(! $canBuy)>−</button>
                    <input type="number" name="quantity" value="1" min="1" max="{{ $maxQty }}" data-quantity-input @disabled(! $canBuy)>
                    <button type="button" data-quantity-increase aria-label="Increase quantity" @disabled(! $canBuy)>+</button>
                </div>
                <button class="s3-add" type="submit" style="width:min(199px, 100%);margin:0;" @disabled(! $canBuy)>Add To Cart</button>
                <a href="{{ route('profile') }}" style="width:50px;height:50px;display:grid;place-items:center;border:1px solid #eee;">♡</a>
            </form>
            <p style="margin-top:16px;"><small>Guaranteed Safe Checkout</small></p>
            <img src="{{ asset('images/storefront/pay.svg') }}" alt="">
            <div class="s3-meta" style="margin-top:16px;">
                <div><strong>SKU:</strong> {{ $variant?->sku }}</div>
                <div><strong>Category:</strong> {{ $product->category?->name }}</div>
                @if($variant?->color)<div><strong>Color:</strong> {{ $variant->color }}</div>@endif
                @if($variant?->size)<div><strong>Size:</strong> {{ $variant->size }}</div>@endif
            </div>
        </div>
        <aside>
            <div class="s3-paycard" style="min-height:171px;">
                <p>Brand: {{ $product->seller?->sellerProfile?->business_name ?? 'JEAP' }}</p>
            </div>
            <div class="s3-summary" style="margin-top:10px;min-height:292px;">
                <h3>Your Cart</h3>
                @forelse($cartItems as $item)
                    <div class="s3-line" style="align-items:flex-start;">
                        @if($item->variant?->product?->primaryImage())
                            <img src="{{ asset($item->variant->product->primaryImage()->path) }}" alt="" width="70" height="70" style="object-fit:contain;">
                        @endif
                        <div>
                            {{ $item->variant?->product?->name }}<br>
                            <small>{{ $item->quantity }} × ₱{{ number_format($item->unit_price, 2) }}</small>
                        </div>
                    </div>
                @empty
                    <p>Cart is empty.</p>
                @endforelse
                <div class="s3-line"><span>Sub Total:</span><strong>₱{{ number_format($cartTotal, 2) }}</strong></div>
                <div style="display:flex;gap:8px;margin-top:16px;">
                    <a class="s3-btn" href="{{ route('cart.index') }}" style="min-width:126px;">view cart</a>
                    <a class="s3-btn" href="{{ route('checkout') }}" style="min-width:126px;">checkout</a>
                </div>
            </div>
            <p style="margin-top:12px;">🚚 Ships from Philippines</p>
        </aside>
    </div>
    <div class="s3-related">
        <h3>related products</h3>
        <div class="s3-relgrid">
            @foreach(($related ?? collect())->take(5) as $item)
                @php $v = $item->defaultVariant(); $img = $item->primaryImage(); @endphp
                <article class="s3-relcard">
                    <a href="{{ route('products.show', $item->slug) }}">
                        @if($img)<img src="{{ asset($img->path) }}" alt="">@endif
                        <h6>{{ $item->name }}</h6>
                        <div class="price">₱{{ number_format($v?->price ?? 0, 2) }}</div>
                    </a>
                </article>
            @endforeach
        </div>
    </div>
</section>
@endsection
