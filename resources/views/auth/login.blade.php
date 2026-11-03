@extends('layouts.storefront')

@section('title', 'Log in')
@section('crumb')
    <span>Log in</span>
@endsection

@section('content')
<section class="s3-main auth-shell">
    <aside class="auth-aside">
        <p class="status-kicker">Account</p>
        <h1>Welcome back</h1>
        <p>Log in to track orders, chat with sellers, and check out with Cash on Delivery.</p>
        <ul class="auth-perks">
            <li>Cash on Delivery</li>
            <li>₱{{ number_format(config('jeap.shipping_fee'), 0) }} flat shipping</li>
            <li>Ships with {{ config('jeap.courier_name') }}</li>
        </ul>
        <img src="{{ asset('images/storefront/login.svg') }}" alt="">
    </aside>
    <div class="auth-card">
        <h2>Log in</h2>
        <p class="lede">Use your JEAP email or continue with Google.</p>
        @if (session('status'))<p class="s3-alert" role="status">{{ session('status') }}</p>@endif
        @if ($errors->any())
            <p class="err">{{ $errors->first() }}</p>
        @endif
        <form method="post" action="{{ route('login') }}">
            @csrf
            <div class="s3-field">
                <label for="login-email">Email address</label>
                <input id="login-email" type="email" name="email" value="{{ old('email') }}" placeholder="you@email.com" autocomplete="email" required>
            </div>
            <div class="s3-field">
                <label for="login-password">Password</label>
                <div class="s3-pass">
                    <input id="login-password" type="password" name="password" placeholder="Password" autocomplete="current-password" required>
                </div>
            </div>
            <p class="auth-forgot"><a href="{{ route('password.request') }}">Forgot password?</a></p>
            <button class="auth-submit" type="submit">Log in</button>
            <div class="s3-auth-divider"><span>OR</span></div>
            @include('partials.google-auth-button', ['from' => 'login'])
            <div class="auth-links">
                <a href="{{ route('register') }}">New here? Sign up</a>
                <a href="{{ route('register.seller') }}">Sell on JEAP</a>
            </div>
        </form>
    </div>
</section>
@endsection
