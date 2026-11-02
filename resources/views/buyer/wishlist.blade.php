@extends('layouts.storefront')

@section('title', 'Wishlist | JEAP')
@section('content')
<main class="buyer-home buyer-wishlist" data-figma="05_Wishlist_Follow 1">
    <header class="buyer-home-heading">
        <div><span class="buyer-home-eyebrow">YOUR JEAP ACCOUNT</span><h1>Wishlist &amp; followed stores</h1><p>Keep products you like and see the sellers you follow.</p></div>
        <a class="buyer-home-shop" href="{{ route('products.index') }}">Continue shopping <span aria-hidden="true">→</span></a>
    </header>
    @if(session('toast'))<div class="buyer-home-flash" role="status">{{ session('toast') }}</div>@endif

    <section class="buyer-orders-panel" aria-labelledby="wishlist-products-title">
        <div class="buyer-orders-heading"><div><span class="buyer-home-eyebrow">SAVED FOR LATER</span><h2 id="wishlist-products-title">Saved products</h2></div><span>{{ $products->total() }} products</span></div>
        <div class="s3-grid4">
            @forelse($products as $product)
                @php($variant = $product->defaultVariant())
                <article class="s3-tile">
                    <a href="{{ route('products.show', $product->slug) }}">
                        @if($product->primaryImage())<img src="{{ asset($product->primaryImage()->path) }}" alt="{{ $product->name }}">@endif
                        <h3>{{ $product->name }}</h3><span class="price">₱{{ number_format((float) ($variant?->price ?? 0), 2) }}</span>
                    </a>
                    <form method="post" action="{{ route('buyer.wishlist.remove', $product) }}">@csrf @method('DELETE')<button type="submit">Remove from wishlist</button></form>
                </article>
            @empty
                <p>Your wishlist is empty. Save a product from its page and it will appear here.</p>
            @endforelse
        </div>
        @if($products->hasPages())<div class="buyer-orders-pagination">{{ $products->links() }}</div>@endif
    </section>

    <section class="buyer-orders-panel" aria-labelledby="followed-sellers-title">
        <div class="buyer-orders-heading"><div><span class="buyer-home-eyebrow">STORES YOU LIKE</span><h2 id="followed-sellers-title">Followed sellers</h2></div><span>{{ $followedSellers->count() }} stores</span></div>
        @forelse($followedSellers as $seller)
            <article class="buyer-order-row"><div class="buyer-order-main"><strong>{{ $seller->sellerProfile?->business_name ?? $seller->name }}</strong><p>{{ $seller->products()->where('status', 'active')->count() }} active products</p></div><form method="post" action="{{ route('buyer.sellers.unfollow', $seller) }}">@csrf @method('DELETE')<button type="submit">Unfollow</button></form></article>
        @empty
            <p>You are not following any sellers yet. Follow a store from a product page.</p>
        @endforelse
    </section>
</main>
@endsection
