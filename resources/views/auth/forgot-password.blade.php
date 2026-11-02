@extends('layouts.storefront')

@section('title', 'Forgot password')
@section('crumb')
    <span>Forgot password</span>
@endsection

@section('content')
<section class="s3-main s3-auth">
    <div class="s3-auth-art"><img src="{{ asset('images/storefront/login.svg') }}" alt=""></div>
    <div class="s3-auth-form">
        <h2>Forgot password</h2>
        <p class="lede">Enter the email on your JEAP account. We’ll send a reset link if it is registered.</p>
        @if (session('status'))<p class="s3-alert" role="status">{{ session('status') }}</p>@endif
        @if (session('password_reset_preview'))<p class="s3-alert" role="status">Email sending is not configured yet. Use this reset link: <a href="{{ session('password_reset_preview') }}">Reset password</a></p>@endif
        @if ($errors->any())<p class="err">{{ $errors->first() }}</p>@endif
        <form method="post" action="{{ route('password.email') }}">
            @csrf
            <div class="s3-field"><label for="forgot-email">Email Address</label><input id="forgot-email" type="email" name="email" value="{{ old('email') }}" autocomplete="email" required></div>
            <p><button class="s3-btn" type="submit">Send reset link</button></p>
        </form>
        <p><a class="s3-link" href="{{ route('login') }}">Back to log in</a></p>
    </div>
</section>
@endsection
