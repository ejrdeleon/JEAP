<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>@yield('title', 'JEAP') — Shop smart. Delivered easy.</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700;800&display=swap" rel="stylesheet">
    @vite(['resources/css/app.css', 'resources/js/app.js'])
</head>
<body class="storefront">
    @guest
        <div class="storefront-bleed topbar">
            <span class="pill">Special</span>
            <span>Get 10% <strong>DISCOUNT</strong> for first order</span>
            <a href="{{ route('register') }}">Register Now</a>
        </div>
    @endguest

    <header class="site-header">
        <div class="storefront-pad header-row">
            <a class="logo" href="{{ route('home') }}">
                <img src="{{ asset('images/storefront/logo.svg') }}" alt="JEAP" width="88" height="40">
            </a>
            <form class="search-cat" action="{{ route('products.index') }}" method="get">
                @php
                    $activeCatSlug = request('category');
                    $activeCatName = 'All Categories';
                    if ($activeCatSlug) {
                        $activeCatName = optional(collect($navCategories ?? [])->firstWhere('slug', $activeCatSlug))->name ?? 'All Categories';
                    }
                @endphp
                <div class="cat-select" data-cat-select>
                    <button type="button" class="cat-select-btn" data-cat-toggle aria-haspopup="listbox" aria-expanded="false">
                        <span data-cat-label>{{ $activeCatName }}</span>
                        <svg class="cat-chevron" width="10" height="6" viewBox="0 0 10 6" fill="none" aria-hidden="true">
                            <path d="M1 1.2L5 4.8L9 1.2" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"/>
                        </svg>
                    </button>
                    <ul class="cat-select-menu" data-cat-menu role="listbox">
                        <li>
                            <button type="button" role="option" data-value="" class="{{ $activeCatSlug ? '' : 'is-active' }}">All Categories</button>
                        </li>
                        @foreach($navCategories ?? [] as $cat)
                            <li>
                                <button type="button" role="option" data-value="{{ $cat->slug }}" class="{{ $activeCatSlug === $cat->slug ? 'is-active' : '' }}">{{ $cat->name }}</button>
                            </li>
                        @endforeach
                    </ul>
                    <input type="hidden" name="category" value="{{ $activeCatSlug }}" data-cat-input>
                </div>
                <input type="search" name="q" placeholder="Search anything..." value="{{ request('q') }}">
                <button type="submit" aria-label="Search">⌕</button>
            </form>
            <div class="hotline">
                <div>
                    <small>Hotline 24/7</small>
                    <strong>{{ config('jeap.hotline') }}</strong>
                </div>
            </div>
            <div class="header-icons">
                <a href="{{ auth()->check() ? route('profile') : route('login') }}" aria-label="Account">👤</a>
                <a href="{{ route('cart.index') }}" aria-label="Cart">
                    🛒
                    <span class="cart-count">{{ $cartCount ?? 0 }}</span>
                </a>
                <button type="button" class="nav-toggle" data-nav-toggle aria-expanded="false" aria-controls="site-nav">Menu</button>
            </div>
        </div>
        <nav id="site-nav" class="storefront-pad subnav">
            <div class="subnav-bar">
                <div class="subnav-left">
                    <a class="nav-chip {{ request()->routeIs('home') ? 'is-active' : '' }}" href="{{ route('home') }}">Home</a>
                    <a class="nav-chip {{ request()->routeIs('products.*') ? 'is-active' : '' }}" href="{{ route('products.index') }}">Products</a>
                    <a class="nav-chip {{ request()->routeIs('about') ? 'is-active' : '' }}" href="{{ route('about') }}">About</a>
                    <a class="nav-chip {{ request()->routeIs('contact') ? 'is-active' : '' }}" href="{{ route('contact') }}">Contact</a>
                    @auth
                        @if (auth()->user()->hasAnyRole(['admin', 'super-admin']))
                            <a class="nav-chip nav-chip--accent" href="{{ route('admin.dashboard') }}">Admin</a>
                        @elseif (auth()->user()->hasRole('seller'))
                            <a class="nav-chip nav-chip--accent" href="{{ route('seller.dashboard') }}">Seller</a>
                        @elseif (auth()->user()->hasRole('courier'))
                            <a class="nav-chip nav-chip--accent" href="{{ route('courier.dashboard') }}">Rider</a>
                        @elseif (auth()->user()->hasRole('logistics'))
                            <a class="nav-chip nav-chip--accent" href="{{ route('logistics.dashboard') }}">Logistics</a>
                        @elseif (auth()->user()->hasRole('buyer'))
                            <a class="nav-chip nav-chip--accent" href="{{ route('buyer.addresses') }}">Delivery addresses</a>
                        @endif
                    @endauth
                </div>
                <div class="subnav-right">
                    <a class="nav-chip nav-chip--accent {{ request()->routeIs('register.seller') ? 'is-active' : '' }}" href="{{ route('register.seller') }}">Sell on JEAP</a>
                    <a class="nav-chip {{ request()->routeIs('shipping.home') ? 'is-active' : '' }}" href="{{ route('shipping.home') }}" @if(request()->routeIs('shipping.home')) aria-current="page" @endif>Shipping</a>
                    <a class="nav-chip {{ request()->routeIs('shipping.track') ? 'is-active' : '' }}" href="{{ route('shipping.track') }}" @if(request()->routeIs('shipping.track')) aria-current="page" @endif>Order Tracking</a>
                </div>
            </div>
        </nav>
    </header>

    @hasSection('crumb')
        <div class="storefront-pad page-crumb">
            <a href="{{ route('home') }}">Home</a>
            <span>/</span>
            @yield('crumb')
        </div>
    @endif

    <main>
        @yield('content')
    </main>

    <footer class="site-footer">
        <div class="storefront-pad">
            <div class="footer-perks">
                <div>Free Shipping over ₱99</div>
                <div>30 Days money back</div>
                <div>100% Secure Payment</div>
                <div>24/7 Dedicated Support</div>
            </div>
            <div class="footer-grid">
                <div>
                    <strong>JEAP — Online Electronic Market</strong>
                    <p>hotline 24/7<br><strong>{{ config('jeap.hotline') }}</strong></p>
                    <p>Shop smart. Delivered easy. Philippine marketplace with in-house logistics.</p>
                </div>
                <div>
                    <strong>Top Categories</strong>
                    <p><a href="{{ route('products.index') }}">TV / Televisions</a><br>Computers<br>Mobiles<br>Kitchen</p>
                </div>
                <div>
                    <strong>Company</strong>
                    <p><a href="{{ route('about') }}">About JEAP</a><br><a href="{{ route('contact') }}">Contact</a></p>
                </div>
                <div>
                    <strong>Help Center</strong>
                    <p><a href="{{ route('help') }}">Customer Service</a><br><a href="{{ route('shipping.track') }}">Track order</a></p>
                </div>
                <div>
                    <strong>Partner</strong>
                    <p><a href="{{ route('register.seller') }}">Become Seller</a><br><a href="{{ route('register.logistics') }}">Sorting Center</a></p>
                </div>
            </div>
        </div>
        <div class="footer-legal storefront-pad">
            <span>© {{ date('Y') }} JEAP. All Rights Reserved</span>
            <span>COD only in v1 · PHP</span>
        </div>
    </footer>

    @if (session('toast'))
        <div class="toast">{{ session('toast') }}</div>
    @endif
</body>
</html>
