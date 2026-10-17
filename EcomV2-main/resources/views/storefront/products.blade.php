@extends('layouts.storefront')

@section('title', 'Product')
@section('crumb')
    <a href="{{ route('products.index') }}">Shop</a>
    <span>/</span>
    <span>Top Cell Phones &amp; Tablets</span>
@endsection

@section('content')
<section class="s3-main" data-figma="Product 7:813">
    <div class="s3-bannerpair">
        <a class="s3-promo" href="{{ route('products.index', ['category' => 'mobiles']) }}">
            <h3>top cell phones &amp; tablets</h3>
            <img src="{{ asset('images/storefront/catalog-banner.svg') }}?v=2" alt="Noise Cancelling headphones">
        </a>
        <a class="s3-promo s3-promo--side" href="{{ route('products.index', ['category' => 'mobiles']) }}">
            <img src="{{ asset('images/storefront/catalog-side.svg') }}?v=2" alt="Redmi Note 12">
        </a>
    </div>
    <div class="s3-popcats">
        <h3>popular categories</h3>
        <div class="s3-popgrid">
            @foreach($categories->take(10) as $category)
                <a class="s3-pop" href="{{ route('products.index', ['category' => $category->slug]) }}">
                    <div>
                        <strong>{{ $category->name }}</strong>
                        <small>{{ $category->products_count ?? '' }} Items</small>
                    </div>
                    @if($category->image_path)
                        <img src="{{ asset($category->image_path) }}" alt="" width="50" height="50" onerror="this.style.display='none'">
                    @endif
                </a>
            @endforeach
        </div>
    </div>
    <div class="s3-cat">
        <aside>
            <div class="s3-sidebox">
                <h3>categories</h3>
                <a class="{{ !request('category') ? 'is-on' : '' }}" href="{{ route('products.index') }}">All Categories</a>
                @foreach($categories as $category)
                    <a class="{{ request('category') === $category->slug ? 'is-on' : '' }}" href="{{ route('products.index', ['category' => $category->slug]) }}">{{ $category->name }}</a>
                @endforeach
            </div>
            <div class="s3-sidebox">
                <h3>filters <a href="{{ route('products.index') }}" style="float:right;font-size:13px;">Reset All</a></h3>
                <p>By Brands / Price / Color — visual filters from Figma; catalog still filters by category + search.</p>
            </div>
        </aside>
        <div>
            <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:16px;">
                <strong>{{ $products->total() }} items</strong>
                <form method="get">
                    @if(request('category'))<input type="hidden" name="category" value="{{ request('category') }}">@endif
                    <input name="q" value="{{ request('q') }}" placeholder="Search" style="height:43px;border:1px solid #e5e5ee;padding:0 12px;">
                </form>
            </div>
            <div class="s3-grid4">
                @forelse($products as $product)
                    @php $variant = $product->defaultVariant(); $img = $product->primaryImage(); @endphp
                    <a class="s3-tile" href="{{ route('products.show', $product->slug) }}">
                        @if($img)
                            <img src="{{ asset($img->path) }}" alt="{{ $product->name }}">
                        @else
                            <img src="{{ asset('images/storefront/login.svg') }}" alt="">
                        @endif
                        <h6>{{ $product->name }}</h6>
                        <div class="price">₱{{ number_format($variant?->price ?? 0, 2) }}
                            @if($variant?->compare_at_price)<span class="compare">₱{{ number_format($variant->compare_at_price, 2) }}</span>@endif
                        </div>
                        <span class="s3-chip">free shipping</span>
                        <p class="in-stock">{{ $variant && $variant->stock > 0 ? '● In stock' : 'Out of stock' }}</p>
                    </a>
                @empty
                    <p>No products found.</p>
                @endforelse
            </div>
            <div style="margin:24px 0;">{{ $products->links() }}</div>
        </div>
    </div>
</section>
@endsection
