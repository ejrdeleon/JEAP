@extends('layouts.storefront')

@section('title', 'Shop')
@section('crumb')
    <span>Shop</span>
@endsection

@section('content')
<section class="s3-main">
    <div class="s3-bannerpair">
        <a class="s3-promo" href="{{ route('products.index') }}">
            <h3>Shop JEAP marketplace</h3>
            <img src="{{ asset('images/storefront/catalog-banner.svg') }}?v=2" alt="">
        </a>
        <a class="s3-promo s3-promo--side" href="{{ route('products.index', ['category' => 'mobile-gadgets']) }}">
            <img src="{{ asset('images/storefront/catalog-side.svg') }}?v=2" alt="">
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
                <form method="get" class="catalog-filter-form">
                    @if(request('q'))<input type="hidden" name="q" value="{{ request('q') }}">@endif
                    @if(request('category'))<input type="hidden" name="category" value="{{ request('category') }}">@endif
                    <label>Minimum price <input type="number" name="min_price" min="0" step="0.01" value="{{ request('min_price') }}" placeholder="₱ 0"></label>
                    <label>Maximum price <input type="number" name="max_price" min="0" step="0.01" value="{{ request('max_price') }}" placeholder="No limit"></label>
                    <label>Sort by
                        <select name="sort">
                            <option value="relevance" @selected(request('sort', 'relevance') === 'relevance')>Recommended</option>
                            <option value="newest" @selected(request('sort') === 'newest')>Newest</option>
                            <option value="price_asc" @selected(request('sort') === 'price_asc')>Price: low to high</option>
                            <option value="price_desc" @selected(request('sort') === 'price_desc')>Price: high to low</option>
                        </select>
                    </label>
                    <label class="catalog-stock-filter"><input type="checkbox" name="in_stock" value="1" @checked(request()->boolean('in_stock'))> In stock only</label>
                    <button type="submit">Apply filters</button>
                </form>
            </div>
        </aside>
        <div>
            <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:16px;">
                <strong>{{ $products->total() }} items</strong>
                <form method="get" class="catalog-search-form">
                    @if(request('category'))<input type="hidden" name="category" value="{{ request('category') }}">@endif
                    @foreach(['min_price', 'max_price', 'sort', 'in_stock'] as $filter)<input type="hidden" name="{{ $filter }}" value="{{ request($filter) }}">@endforeach
                    <input name="q" value="{{ request('q') }}" placeholder="Search products" style="height:43px;border:1px solid #e5e5ee;padding:0 12px;">
                    <button type="submit">Search</button>
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
                        <span class="s3-chip">₱{{ number_format(\App\Commerce\InventoryPolicy::shippingFee(), 0) }} shipping</span>
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
