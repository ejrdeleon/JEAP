@extends('layouts.storefront')

@section('title', 'About')
@section('crumb')
    <span>About</span>
@endsection

@section('content')
<section class="s3-main about-page" data-figma="About 1:4158">
    <div class="about-hero">
        <p class="about-eyebrow">ABOUT JEAP</p>
        <h1>A better way to shop from marketplace sellers.</h1>
        <p>JEAP is a Philippine multi-vendor marketplace that brings product discovery and Cash on Delivery together in one storefront.</p>
        <div class="about-actions">
            <a class="s3-btn" href="{{ route('products.index') }}">Explore products</a>
            <a class="about-text-link" href="{{ route('register.seller') }}">Sell on JEAP <span aria-hidden="true">→</span></a>
        </div>
        <span class="about-hero-mark" aria-hidden="true">JEAP</span>
    </div>

    <section class="about-intro" aria-labelledby="about-intro-title">
        <div>
            <p class="about-eyebrow">OUR APPROACH</p>
            <h2 id="about-intro-title">One marketplace, made for everyday shopping.</h2>
        </div>
        <p>Browse products from participating sellers, search by category, and place eligible orders with Cash on Delivery. JEAP also provides separate applications for sellers, riders, and logistics partners.</p>
    </section>

    <div class="about-cards">
        <article class="about-card">
            <span class="about-card-number">01</span>
            <h3>Find what you need</h3>
            <p>Explore the catalog by category or search for a product by name.</p>
            <a href="{{ route('products.index') }}">Browse products <span aria-hidden="true">→</span></a>
        </article>
        <article class="about-card">
            <span class="about-card-number">02</span>
            <h3>Choose Cash on Delivery</h3>
            <p>Place your order through the current checkout with Cash on Delivery.</p>
            <a href="{{ route('help') }}">Visit the help center <span aria-hidden="true">→</span></a>
        </article>
        <article class="about-card">
            <span class="about-card-number">03</span>
            <h3>Join the marketplace</h3>
            <p>Seller, rider, and logistics partner applications are available on JEAP.</p>
            <a href="{{ route('register.seller') }}">Learn about selling <span aria-hidden="true">→</span></a>
        </article>
    </div>

    <section class="about-contact">
        <div>
            <p class="about-eyebrow">HERE TO HELP</p>
            <h2>Questions about shopping with JEAP?</h2>
            <p>Visit the help center or get in touch with our team.</p>
        </div>
        <div class="about-actions">
            <a class="s3-btn" href="{{ route('contact') }}">Contact JEAP</a>
            <a class="about-text-link" href="{{ route('help') }}">Help center <span aria-hidden="true">→</span></a>
        </div>
    </section>
</section>
@endsection
