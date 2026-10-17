@extends('layouts.storefront')

@section('title', 'Home 3')

@section('content')
<section class="storefront-pad" data-figma="Home 3">
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
                <h2>EKO 40"</h2>
                <p>Smart Full HD</p>
                <a class="btn-dark" href="{{ route('products.index', ['category' => 'televisions']) }}">Shop Now</a>
            </div>
            <div class="hero-slide" style="background:linear-gradient(90deg,#1b1b28,#4b3ec4);">
                <h2>iPad mini</h2>
                <p>Mega Power in mini size</p>
                <a class="btn-dark" href="{{ route('products.index', ['category' => 'computers']) }}">Shop Now</a>
            </div>
            <div class="hero-controls">
                <button type="button" data-hero-prev>‹</button>
                <button type="button" data-hero-next>›</button>
            </div>
        </div>
        <aside class="promo-side">
            <h3>Humidifying Fan</h3>
            <p>From ₱299</p>
            <a class="btn-dark" href="{{ route('products.index') }}">Discover Now</a>
        </aside>
    </div>

    <div class="mid-banners">
        <article class="banner blue">
            <h3>iPad mini</h3>
            <p>Mega Power in mini size</p>
            <a class="btn-dark" href="{{ route('products.index') }}" style="height:34px;min-width:107px;">Shop Now</a>
        </article>
        <article class="banner peach">
            <small>from</small>
            <h3>Air</h3>
            <strong>₱169</strong>
        </article>
        <article class="banner lilac">
            <small>washing machine</small>
            <h3>Anatico</h3>
            <a class="btn-dark" href="{{ route('products.index') }}" style="height:34px;min-width:107px;">Shop Now</a>
        </article>
    </div>

    <div class="section-head">
        <h2>Best Weekly Deals</h2>
        <span>Expires in: 02 d : 09 h : 35 m</span>
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
        @foreach(['Vacuum Robot','Bluetooth Speaker','Oled TV','Security Camera','Macbook M1','Smart Washing Machine','iPad Mini 2023','PS5','Earbuds'] as $tag)
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
