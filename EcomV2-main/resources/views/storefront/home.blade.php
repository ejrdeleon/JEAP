@extends('layouts.storefront')

@section('title', 'Home')

@section('content')
<section class="storefront-pad">
    @if ($announcements->isNotEmpty())
        <section class="store-announcements" aria-label="Marketplace announcements">
            @foreach ($announcements as $announcement)
                <article><strong>{{ $announcement->title }}</strong><p>{{ $announcement->body }}</p></article>
            @endforeach
        </section>
    @endif
    <div class="section-head">
        <h2>Popular Categories</h2>
        <a href="{{ route('products.index') }}">View All →</a>
    </div>
    <div class="cat-row">
        @foreach($categories as $category)
            <a class="cat-item" href="{{ route('products.index', ['category' => $category->slug]) }}">
                <div class="bubble">
                    @if ($category->image_path)
                        <img src="{{ asset($category->image_path) }}" alt="{{ $category->name }}">
                    @endif
                </div>
                <span>{{ $category->name }}</span>
            </a>
        @endforeach
    </div>

    <div class="hero-grid">
        <div class="hero-slider" data-hero>
            <div class="hero-slide is-active">
                <h2>Shop from local sellers</h2>
                <p>Cash on Delivery · ₱{{ number_format(config('jeap.shipping_fee'), 0) }} shipping</p>
                <a class="btn-dark" href="{{ route('products.index') }}">Shop now</a>
            </div>
            <div class="hero-slide" style="background:linear-gradient(90deg,#1b1b28,#4b3ec4);">
                <h2>Delivered in-house</h2>
                <p>JEAP logistics from pickup to your door</p>
                <a class="btn-dark" href="{{ route('products.index') }}">Browse products</a>
            </div>
            <div class="hero-controls">
                <button type="button" data-hero-prev>‹</button>
                <button type="button" data-hero-next>›</button>
            </div>
        </div>
        <aside class="promo-side">
            <h3>Sell on JEAP</h3>
            <p>Apply as a seller</p>
            <a class="btn-dark" href="{{ route('register.seller') }}">Get started</a>
        </aside>
    </div>

    <div class="mid-banners">
        <article class="banner blue">
            <h3>Mobile & gadgets</h3>
            <p>Phones and accessories from JEAP sellers</p>
            <a class="btn-dark" href="{{ route('products.index', ['category' => 'mobile-gadgets']) }}" style="height:34px;min-width:107px;">Shop now</a>
        </article>
        <article class="banner peach">
            <small>Shipping</small>
            <h3>₱{{ number_format(config('jeap.shipping_fee'), 0) }}</h3>
            <strong>flat rate</strong>
        </article>
        <article class="banner lilac">
            <small>Payment</small>
            <h3>COD</h3>
            <a class="btn-dark" href="{{ route('products.index') }}" style="height:34px;min-width:107px;">Shop now</a>
        </article>
    </div>

    <div class="section-head">
        <h2>Best weekly deals</h2>
        <span>Listed products with stock of 10 or more</span>
    </div>
    <div class="product-grid">
        @foreach($deals as $product)
            @php $variant = $product->defaultVariant(); @endphp
            <a class="product-card" href="{{ route('products.show', $product->slug) }}">
                <div class="media">
                    @if ($product->primaryImage())
                        <img src="{{ asset($product->primaryImage()->path) }}" alt="{{ $product->name }}">
                    @endif
                </div>
                <div class="info">
                    @if (($variant?->attributes['badge'] ?? null))
                        <span class="badge">{{ $variant->attributes['badge'] }}</span>
                    @endif
                    <div>{{ $product->name }}</div>
                    <div>
                        <span class="price">₱{{ number_format($variant?->price ?? 0, 2) }}</span>
                        @if ($variant?->compare_at_price)
                            <span class="compare">₱{{ number_format($variant->compare_at_price, 2) }}</span>
                        @endif
                    </div>
                </div>
            </a>
        @endforeach
    </div>
    <p style="text-align:center;margin:28px 0;">
        <a class="btn-dark" href="{{ route('products.index') }}" style="height:53px;">See All Products</a>
    </p>

    <div class="section-head">
        <h2>Trending Search</h2>
    </div>
    <div class="tags">
        @foreach(['Smartphone','Laptop','Kitchen','Gaming','Cameras','Home appliances','Sports'] as $tag)
            <a class="tag" href="{{ route('products.index', ['q' => $tag]) }}">{{ $tag }}</a>
        @endforeach
    </div>

    <div class="section-head">
        <h2>Featured Products</h2>
    </div>
    <div class="product-grid">
        @foreach($products as $product)
            @php $variant = $product->defaultVariant(); @endphp
            <a class="product-card" href="{{ route('products.show', $product->slug) }}">
                <div class="media">
                    @if ($product->primaryImage())
                        <img src="{{ asset($product->primaryImage()->path) }}" alt="{{ $product->name }}">
                    @endif
                </div>
                <div class="info">
                    <div>{{ $product->name }}</div>
                    <div><span class="price">₱{{ number_format($variant?->price ?? 0, 2) }}</span></div>
                </div>
            </a>
        @endforeach
    </div>
</section>
@endsection
