@extends('layouts.storefront')

@section('title', $product->name)
@section('crumb')
    <a href="{{ route('products.index') }}">Shop</a>
    <span>/</span>
    <a href="{{ route('products.index', ['category' => $product->category?->slug]) }}">{{ $product->category?->name }}</a>
    <span>/</span>
    <span>{{ $product->name }}</span>
@endsection

@section('content')
@php
    $variant = $product->defaultVariant();
    $images = $product->images;
    $main = $product->primaryImage();
    $maxQty = $variant ? min(\App\Commerce\InventoryPolicy::maxQtyPerProduct(), $variant->stock) : 1;
    $canBuy = $variant?->isSellable();
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
                @forelse($images as $image)
                    <img src="{{ asset($image->path) }}" alt="">
                @empty
                    <span></span><span></span><span></span>
                @endforelse
            </div>
        </div>
        <div>
            <h1>{{ $product->name }}</h1>
            <div class="pdp-price">₱{{ number_format($variant?->price ?? 0, 2) }}
                @if($variant?->compare_at_price) - ₱{{ number_format($variant->compare_at_price, 2) }} @endif
            </div>
            @if($product->description)
                <p class="s3-bullets">{{ $product->description }}</p>
            @endif
            <span class="s3-chip">₱{{ number_format(\App\Commerce\InventoryPolicy::shippingFee(), 0) }} shipping · COD</span>
            <div style="margin:16px 0;">
                @if($variant?->color)
                    <strong>Color:</strong> {{ $variant->color }}
                @endif
                @if($variant?->size)<p style="margin-top:12px;"><strong>Size:</strong> {{ $variant->size }}</p>@endif
            </div>
            <div class="s3-meta">
                <div><strong>SKU:</strong> {{ $variant?->sku }}</div>
                <div><strong>Category:</strong> {{ $product->category?->name }}</div>
                <div><strong>Store:</strong> @if($product->seller)<a href="{{ route('stores.show', $product->seller) }}">{{ $product->seller->sellerProfile?->business_name ?? $product->seller->name }}</a>@else JEAP @endif</div>
            </div>
        </div>
        <aside>
            <div class="s3-paycard">
                <small>Total Price:</small>
                <div class="price">₱{{ number_format($variant?->price ?? 0, 2) }}</div>
                <p class="in-stock" aria-live="polite">{{ $canBuy ? '● In stock' : 'Not available to sell yet' }}</p>
                <form method="post" action="{{ route('cart.add') }}" data-cart-add-form data-existing-quantity="{{ $cartQuantity }}">
                    @csrf
                    @if($variant)
                        <input type="hidden" name="product_variant_id" value="{{ $variant->id }}">
                    @endif
                    <div class="s3-qty" data-quantity-control style="width:100%;height:53px;border-radius:4px;">
                        <button type="button" data-quantity-decrease aria-label="Decrease quantity" @disabled(! $canBuy)>−</button>
                        <input type="number" name="quantity" value="1" min="1" max="{{ $maxQty }}" data-quantity-input @disabled(! $canBuy)>
                        <button type="button" data-quantity-increase aria-label="Increase quantity" @disabled(! $canBuy)>+</button>
                    </div>
                    <button class="s3-add" type="submit" @disabled(! $canBuy)>Add To Cart</button>
                    @if(! $canBuy)
                        <p class="cart-stock is-unavailable">Sellers need at least {{ \App\Commerce\InventoryPolicy::minSellableStock() }} units in stock before this can be sold. Limit {{ \App\Commerce\InventoryPolicy::maxQtyPerProduct() }} per product in cart.</p>
                    @endif
                </form>
                @auth
                    @if(auth()->user()->hasRole('buyer'))
                        <div class="pdp-save-actions">
                            <form method="post" action="{{ route($isWishlisted ? 'buyer.wishlist.remove' : 'buyer.wishlist.save', $product) }}">
                                @csrf
                                @if($isWishlisted) @method('DELETE') @endif
                                <button type="submit">{{ $isWishlisted ? '♥ Saved to wishlist' : '♡ Save to wishlist' }}</button>
                            </form>
                            <form method="post" action="{{ route($isFollowingSeller ? 'buyer.sellers.unfollow' : 'buyer.sellers.follow', $product->seller) }}">
                                @csrf
                                @if($isFollowingSeller) @method('DELETE') @endif
                                <button type="submit">{{ $isFollowingSeller ? 'Following this store' : 'Follow this store' }}</button>
                            </form>
                        </div>
                    @endif
                @else
                    <a class="pdp-save-link" href="{{ route('login') }}">Sign in to save this product</a>
                @endauth
                <small>Guaranteed Safe Checkout</small>
                <img src="{{ asset('images/storefront/pay.svg') }}" alt="" style="display:block;margin-top:8px;">
            </div>
            <div class="s3-paycard" style="margin-top:10px;">
                <small>Quick Order 24/7</small>
                <h5>{{ config('jeap.hotline') }}</h5>
            </div>
            <p style="margin-top:12px;">🚚 Ships from Philippines</p>
        </aside>
    </div>
    <div class="s3-related">
        <h3>frequently bought together</h3>
        <div class="s3-relgrid">
            @foreach(($related ?? collect())->take(5) as $item)
                @php $v = $item->defaultVariant(); $img = $item->primaryImage(); @endphp
                <article class="s3-relcard">
                    <a href="{{ route('products.show', $item->slug) }}">
                        @if($img)<img src="{{ asset($img->path) }}" alt="{{ $item->name }}">@endif
                        <h6>{{ $item->name }}</h6>
                        <div class="price">₱{{ number_format($v?->price ?? 0, 2) }}</div>
                    </a>
                </article>
            @endforeach
        </div>
        <h3 style="margin-top:40px;">related products</h3>
        <div class="s3-relgrid">
            @foreach(($related ?? collect())->take(5) as $item)
                @php $v = $item->defaultVariant(); $img = $item->primaryImage(); @endphp
                <article class="s3-relcard">
                    <a href="{{ route('products.show', $item->slug) }}">
                        @if($img)<img src="{{ asset($img->path) }}" alt="{{ $item->name }}">@endif
                        <h6>{{ $item->name }}</h6>
                        <div class="price">₱{{ number_format($v?->price ?? 0, 2) }}</div>
                        <span class="s3-chip">₱{{ number_format(\App\Commerce\InventoryPolicy::shippingFee(), 0) }} shipping · COD</span>
                    </a>
                </article>
            @endforeach
        </div>
    </div>
</section>
@endsection
