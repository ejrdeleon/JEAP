@extends('layouts.storefront')

@section('title', 'Login')
@section('crumb')
    <a href="{{ route('about') }}">pages</a>
    <span>/</span>
    <span>login</span>
@endsection

@section('content')
<section class="s3-main s3-auth" data-figma="Login 1:3362">
    <div class="s3-auth-art">
        <img src="{{ asset('images/storefront/login.svg') }}" alt="">
    </div>
    <div class="s3-auth-form">
        <h2>Welcome Back</h2>
        <p class="lede">login to continue</p>
        @if (session('status'))<p class="s3-alert" role="status">{{ session('status') }}</p>@endif
        @if ($errors->any())
            <p class="err">{{ $errors->first() }}</p>
        @endif
        <form method="post" action="{{ route('login') }}">
            @csrf
            <div class="s3-field">
                <label>Email Address</label>
                <input type="email" name="email" value="{{ old('email') }}" placeholder="Example@gmail.com" required>
            </div>
            <div class="s3-field">
                <label>Password</label>
                <div class="s3-pass">
                    <input type="password" name="password" placeholder="...." required>
                </div>
            </div>
            <p><a class="s3-link" href="{{ route('login') }}">Forget Password ?</a></p>
            <p style="margin: 24px 0 12px;"><button class="s3-btn" type="submit">login</button></p>
            <div class="s3-auth-divider"><span>OR</span></div>
            <a class="s3-google-button" href="{{ route('google.redirect', ['from' => 'login']) }}">
                <svg aria-hidden="true" width="18" height="18" viewBox="0 0 48 48" focusable="false"><path fill="#4285F4" d="M43.6 24.5c0-1.4-.1-2.8-.4-4.1H24v7.8h11a9.4 9.4 0 0 1-4.1 6.2v5h6.6c3.9-3.6 6.1-8.8 6.1-14.9Z"/><path fill="#34A853" d="M24 44c5.5 0 10.1-1.8 13.5-4.8l-6.6-5c-1.8 1.2-4.1 2-6.9 2-5.3 0-9.8-3.6-11.4-8.4H5.8v5.2A20 20 0 0 0 24 44Z"/><path fill="#FBBC05" d="M12.6 27.8a12 12 0 0 1 0-7.6V15H5.8a20 20 0 0 0 0 18Z"/><path fill="#EA4335" d="M24 11.8c3 0 5.7 1 7.8 3.1l5.8-5.8C34.1 5.8 29.5 4 24 4A20 20 0 0 0 5.8 15l6.8 5.2c1.6-4.8 6.1-8.4 11.4-8.4Z"/></svg>
                <span>Continue with Google</span>
            </a>
            <p><a class="s3-link" href="{{ route('register') }}">new user ? Register Now</a></p>
            <p><a class="s3-link" href="{{ route('register.seller') }}">Sell on JEAP</a> · <a class="s3-link" href="{{ route('register.logistics') }}">Sorting center</a></p>
        </form>
    </div>
</section>
@endsection
