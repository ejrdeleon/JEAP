@extends('layouts.storefront')

@section('title', 'Wishlist')
@section('crumb')
    <span>Wishlist</span>
@endsection

@section('content')
<main class="wish-page">
    <header class="wish-heading">
        <div>
            <p class="status-kicker">Your JEAP account</p>
            <h1>Wishlist &amp; followed stores</h1>
            <p>Keep products you like, and keep shops you follow in one place.</p>
        </div>
        <a class="wish-shop" href="{{ route('products.index') }}">Continue shopping</a>
    </header>
    @if(session('toast'))<div class="buyer-home-flash" role="status">{{ session('toast') }}</div>@endif

    <section class="wish-panel" aria-labelledby="wishlist-products-title">
        <header class="wish-panel-head">
            <div>
                <span class="wish-eyebrow">Saved for later</span>
                <h2 id="wishlist-products-title">Saved products</h2>
            </div>
            <span>{{ $products->total() }} {{ Str::plural('product', $products->total()) }}</span>
        </header>
        @if($products->isEmpty())
            <div class="wish-empty">
                <h3>Your wishlist is empty</h3>
                <p>Save a product from its page and it will appear here.</p>
                <a href="{{ route('products.index') }}">Browse products</a>
            </div>
        @else
            <div class="wish-product-grid">
                @foreach($products as $product)
                    @php
                        $variant = $product->defaultVariant();
                        $image = $product->primaryImage();
                    @endphp
                    <article class="wish-product">
                        <a class="wish-product-link" href="{{ route('products.show', $product->slug) }}">
                            @if($image)
                                <img src="{{ asset($image->path) }}" alt="{{ $product->name }}">
                            @else
                                <span class="wish-product-ph" aria-hidden="true">JEAP</span>
                            @endif
                            <h3>{{ $product->name }}</h3>
                            <span class="wish-price">₱{{ number_format((float) ($variant?->price ?? 0), 2) }}</span>
                        </a>
                        <form method="post" action="{{ route('buyer.wishlist.remove', $product) }}">
                            @csrf
                            @method('DELETE')
                            <button class="wish-remove" type="submit">Remove</button>
                        </form>
                    </article>
                @endforeach
            </div>
            @if($products->hasPages())
                <div class="wish-pagination">{{ $products->links() }}</div>
            @endif
        @endif
    </section>

    <section class="wish-panel" aria-labelledby="followed-sellers-title">
        <header class="wish-panel-head">
            <div>
                <span class="wish-eyebrow">Stores you like</span>
                <h2 id="followed-sellers-title">Followed sellers</h2>
            </div>
            <span>{{ $followedSellers->count() }} {{ Str::plural('store', $followedSellers->count()) }}</span>
        </header>
        @if($followedSellers->isEmpty())
            <div class="wish-empty">
                <h3>You are not following any sellers yet</h3>
                <p>Follow a store from a product page.</p>
                <a href="{{ route('products.index') }}">Browse stores</a>
            </div>
        @else
            <div class="wish-store-grid">
                @foreach($followedSellers as $seller)
                    @php
                        $shopName = $seller->sellerProfile?->business_name ?: $seller->name;
                        $logo = $seller->sellerProfile?->logo_path;
                    @endphp
                    <article class="wish-store">
                        @if($logo)
                            <img class="wish-store-logo" src="{{ asset($logo) }}" alt="">
                        @else
                            <span class="wish-store-logo is-fallback" aria-hidden="true">{{ strtoupper(substr($shopName, 0, 1)) }}</span>
                        @endif
                        <div class="wish-store-copy">
                            <h3>{{ $shopName }}</h3>
                            <p>{{ $seller->active_products_count }} {{ Str::plural('active product', $seller->active_products_count) }}</p>
                            <a href="{{ route('stores.show', $seller) }}">Visit store</a>
                        </div>
                        <form method="post" action="{{ route('buyer.sellers.unfollow', $seller) }}">
                            @csrf
                            @method('DELETE')
                            <button class="wish-unfollow" type="submit">Unfollow</button>
                        </form>
                    </article>
                @endforeach
            </div>
        @endif
    </section>
</main>
@endsection
