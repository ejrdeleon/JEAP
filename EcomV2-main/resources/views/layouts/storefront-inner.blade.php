<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>@yield('title', 'JEAP') — Shop smart. Delivered easy.</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    @vite(['resources/css/app.css', 'resources/js/app.js'])
</head>
<body class="storefront s3">
    <header class="s3-header">
        <div class="s3-shell">
            <div class="s3-wh">
                <div class="s3-topmini">
                    <span class="s3-hotline-pill">☎ Hotline 24/7</span>
                    <a href="tel:{{ config('jeap.hotline') }}">{{ config('jeap.hotline') }}</a>
                    <div class="s3-topmini-right">
                        <a href="{{ route('register') }}">Sell on JEAP</a>
                        <a href="{{ route('shipping.track') }}">Order Tracking</a>
                        <span>PHP</span>
                        <span>Eng ▾</span>
                    </div>
                </div>
                <nav class="s3-nav">
                    <a class="s3-logo" href="{{ route('home') }}">
                        <img src="{{ asset('images/storefront/logo.svg') }}" alt="JEAP" width="161" height="40">
                    </a>
                    <ul class="s3-menu">
                        <li class="s3-has">
                            <a href="{{ route('home') }}">Homes ▾</a>
                            <div class="s3-drop">
                                <a href="{{ route('home') }}">Home</a>
                            </div>
                        </li>
                        <li class="s3-has">
                            <a href="{{ route('about') }}">Pages ▾</a>
                            <div class="s3-drop">
                                <a href="{{ route('about') }}">About</a>
                                <a href="{{ route('profile') }}">Profile</a>
                                <a href="{{ route('login') }}">Login</a>
                                <a href="{{ route('register') }}">Sign up</a>
                                <a href="{{ route('cart.index') }}">Cart</a>
                                <a href="{{ route('checkout') }}">Checkout</a>
                                <a href="{{ route('help') }}">Help</a>
                            </div>
                        </li>
                        <li class="s3-has">
                            <a class="{{ request()->routeIs('products.*') ? 'is-on' : '' }}" href="{{ route('products.index') }}">Products ▾</a>
                            <div class="s3-drop">
                                <a href="{{ route('products.index') }}">All products</a>
                                @foreach($navCategories ?? [] as $cat)
                                    <a href="{{ route('products.index', ['category' => $cat->slug]) }}">{{ $cat->name }}</a>
                                @endforeach
                            </div>
                        </li>
                        <li>
                            <a class="{{ request()->routeIs('contact') ? 'is-on' : '' }}" href="{{ route('contact') }}">Contact</a>
                        </li>
                    </ul>
                    <div class="s3-side">
                        <div class="s3-icons">
                            <a href="{{ route('products.index') }}" aria-label="Search">⌕</a>
                            <a href="{{ route('help') }}" aria-label="Help">?</a>
                            <a href="{{ auth()->check() ? route('profile') : route('login') }}" aria-label="Account">♡</a>
                        </div>
                        <div class="s3-welcome">
                            <small>welcome</small>
                            @auth
                                <a href="{{ route('profile') }}">{{ auth()->user()->first_name }}</a>
                            @else
                                <a href="{{ route('login') }}">Log in / Sign up</a>
                            @endauth
                        </div>
                        <a class="s3-cartlink" href="{{ route('cart.index') }}">
                            <span class="s3-bag">🛒<span class="s3-num">{{ $cartCount ?? 0 }}</span></span>
                        </a>
                        <div class="s3-welcome">
                            <small>cart</small>
                            <a href="{{ route('cart.index') }}">₱{{ number_format($cartTotal ?? 0, 2) }}</a>
                        </div>
                    </div>
                </nav>
            </div>
            <div class="s3-searchrow">
                <form class="s3-search" action="{{ route('products.index') }}" method="get">
                    <select name="category">
                        <option value="">All Categories</option>
                        @foreach($navCategories ?? [] as $cat)
                            <option value="{{ $cat->slug }}" @selected(request('category') === $cat->slug)>{{ $cat->name }}</option>
                        @endforeach
                    </select>
                    <input type="search" name="q" placeholder="Search anything..." value="{{ request('q') }}">
                    <button type="submit" aria-label="Search">⌕</button>
                </form>
            </div>
            <div class="s3-crumb">
                <a href="{{ route('home') }}">Home</a>
                <span>/</span>
                @yield('crumb')
            </div>
        </div>
    </header>

    <main>
        @yield('content')
    </main>

    <footer class="s3-footer">
        <div class="s3-footer-inner">
            <div class="s3-fg">
                <div>
                    <strong>JEAP — Philippine marketplace</strong>
                    <p class="s3-hot">hotline 24/7</p>
                    <p class="s3-phone">{{ config('jeap.hotline') }}</p>
                    <p>Laguna, Philippines · in-house sorting center logistics</p>
                    <p>hello@jeap.test</p>
                    <div class="s3-soc">
                        <span></span><span></span><span></span><span></span><span></span>
                    </div>
                </div>
                <div>
                    <strong>Categories</strong>
                    @foreach(($navCategories ?? collect())->take(6) as $cat)
                        <p><a href="{{ route('products.index', ['category' => $cat->slug]) }}">{{ $cat->name }}</a></p>
                    @endforeach
                </div>
                <div>
                    <strong>company</strong>
                    <p><a href="{{ route('about') }}">About JEAP</a></p>
                    <p><a href="{{ route('contact') }}">Contact</a></p>
                    <p><a href="{{ route('help') }}">Help</a></p>
                    <p><a href="{{ route('shipping.home') }}">Shipping</a></p>
                </div>
                <div>
                    <strong>help center</strong>
                    <p><a href="{{ route('help') }}">Customer Service</a></p>
                    <p><a href="{{ route('shipping.track') }}">Track order</a></p>
                    <p><a href="{{ route('cart.index') }}">Cart</a></p>
                    <p><a href="{{ route('checkout') }}">Checkout</a></p>
                </div>
                <div>
                    <strong>partner</strong>
                    <p><a href="{{ route('register.seller') }}">Become a seller</a></p>
                    <p><a href="{{ route('register.logistics') }}">Sorting center</a></p>
                </div>
            </div>
            <div class="s3-legal">
                <span>© {{ date('Y') }} JEAP. All Rights Reserved</span>
                <img src="{{ asset('images/storefront/pay.svg') }}" alt="" width="243" height="15">
                <span>Mobile Site</span>
            </div>
        </div>
    </footer>

    @if (session('toast'))
        <div class="toast">{{ session('toast') }}</div>
    @endif
</body>
</html>
