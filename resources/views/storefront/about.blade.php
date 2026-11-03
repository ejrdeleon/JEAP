@extends('layouts.storefront')

@section('title', 'About')
@section('crumb')
    <span>About</span>
@endsection

@section('content')
<section class="s3-main about-page">
    <div class="about-hero">
        <p class="about-eyebrow">ABOUT JEAP</p>
        <h1>About JEAP</h1>
        <p class="about-names">Jules • Ernest • Avril • Philippines</p>
        <p>JEAP stands for Jules, Ernest, Avril, Philippines, an online shopping platform developed to provide customers with a convenient, accessible, and reliable way to shop for different products online.</p>
        <div class="about-actions">
            <a class="s3-btn" href="{{ route('products.index') }}">Explore products</a>
            <a class="about-text-link" href="{{ route('register.seller') }}">Sell on JEAP <span aria-hidden="true">→</span></a>
        </div>
        <span class="about-hero-mark" aria-hidden="true">JEAP</span>
    </div>

    <div class="about-body">
        <section class="about-story">
            <p>JEAP aims to make online shopping easier by allowing customers to explore products, view detailed product information, add items to their shopping carts, and place orders through a user-friendly website and mobile application.</p>
            <p>The platform is designed to provide a smooth shopping experience through organized product listings, convenient checkout, delivery address management, and multiple payment options. It also includes an order management and tracking process, allowing customers to monitor their purchases from order placement until delivery.</p>
            <p>JEAP also provides features for sellers and administrators to manage products, process customer orders, monitor transactions, and oversee platform activities. Through these features, the system aims to establish a more organized and efficient online shopping environment.</p>
        </section>

        <section class="about-purpose">
            <article>
                <p class="about-eyebrow">OUR MISSION</p>
                <h2>Our Mission</h2>
                <p>To provide a convenient, accessible, and user-friendly online shopping experience that connects customers and sellers through technology.</p>
            </article>
            <article>
                <p class="about-eyebrow">OUR VISION</p>
                <h2>Our Vision</h2>
                <p>To become a reliable and innovative online shopping platform that makes digital commerce more accessible and convenient for Filipino consumers.</p>
            </article>
        </section>

        <section class="about-offers">
            <p class="about-eyebrow">WHAT WE OFFER</p>
            <h2>What JEAP Offers</h2>
            <ul>
                <li>
                    <strong>Easy Shopping</strong>
                    <p>Browse and discover products in one platform.</p>
                </li>
                <li>
                    <strong>Product Management</strong>
                    <p>Organized product listings and detailed product information.</p>
                </li>
                <li>
                    <strong>Shopping Cart</strong>
                    <p>Easily manage selected items before checkout.</p>
                </li>
                <li>
                    <strong>Secure Checkout</strong>
                    <p>Convenient order placement and payment options.</p>
                </li>
                <li>
                    <strong>Order Tracking</strong>
                    <p>Monitor orders throughout the delivery process.</p>
                </li>
                <li>
                    <strong>Seller Management</strong>
                    <p>Tools for managing products and customer orders.</p>
                </li>
                <li>
                    <strong>Admin Dashboard</strong>
                    <p>Centralized management of users, products, transactions, and platform activities.</p>
                </li>
            </ul>
        </section>

        <p class="about-tagline">JEAP — Making Online Shopping Easier, One Click at a Time.</p>
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
