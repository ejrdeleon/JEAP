@extends('layouts.storefront')

@section('title', ($seller->sellerProfile?->business_name ?? $seller->name).' | JEAP Store')
@section('content')
<main class="storefront-pad public-store" data-figma="B3_Browse_Store 1">
    <header class="public-store-heading">
        <span class="buyer-home-eyebrow">JEAP SELLER</span>
        <h1>{{ $seller->sellerProfile?->business_name ?? $seller->name }}</h1>
        <p>{{ $seller->sellerProfile?->lineOfBusiness?->name ? 'Shop '.$seller->sellerProfile->lineOfBusiness->name.' and more from this JEAP seller.' : 'Browse products from this JEAP seller.' }}</p>
        @auth
            @if(auth()->user()->hasRole('buyer'))
                @php($isFollowing = auth()->user()->followedSellers()->whereKey($seller->id)->exists())
                <form method="post" action="{{ route($isFollowing ? 'buyer.sellers.unfollow' : 'buyer.sellers.follow', $seller) }}">
                    @csrf @if($isFollowing) @method('DELETE') @endif
                    <button class="catalog-filter-form button" type="submit">{{ $isFollowing ? 'Following this store' : 'Follow this store' }}</button>
                </form>
            @endif
        @endauth
    </header>
    <div class="s3-cat public-store-content">
        <aside class="s3-sidebox"><h2>Store categories</h2><a href="{{ route('stores.show', $seller) }}">All products</a>@foreach($categories as $category)<a href="{{ route('stores.show', ['seller' => $seller, 'category' => $category->slug]) }}">{{ $category->name }}</a>@endforeach</aside>
        <section>
            <form method="get" class="catalog-search-form public-store-search">
                @if(request('category'))<input type="hidden" name="category" value="{{ request('category') }}">@endif
                <input name="q" value="{{ request('q') }}" placeholder="Search this store" aria-label="Search this store">
                <select name="sort" aria-label="Sort products"><option value="newest">Newest</option><option value="price_asc" @selected(request('sort') === 'price_asc')>Price: low to high</option><option value="price_desc" @selected(request('sort') === 'price_desc')>Price: high to low</option></select>
                <button type="submit">Search</button>
            </form>
            <p>{{ $products->total() }} products</p>
            <div class="s3-grid4">
                @forelse($products as $product)
                    @php($variant = $product->defaultVariant())
                    <a class="s3-tile" href="{{ route('products.show', $product->slug) }}">
                        @if($product->primaryImage())<img src="{{ asset($product->primaryImage()->path) }}" alt="{{ $product->name }}">@endif
                        <h6>{{ $product->name }}</h6><span class="price">₱{{ number_format((float) ($variant?->price ?? 0), 2) }}</span>
                    </a>
                @empty<p>No products match this selection.</p>@endforelse
            </div>
            <div class="buyer-orders-pagination">{{ $products->links() }}</div>
        </section>
    </div>
</main>
@endsection
