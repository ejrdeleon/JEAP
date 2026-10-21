@extends('layouts.storefront')

@section('title', 'Verify your email')
@section('crumb')
    <span>Email verification</span>
@endsection

@section('content')
<section class="s3-main s3-auth">
    <div class="s3-auth-art"><img src="{{ asset('images/storefront/login.svg') }}" alt=""></div>
    <div class="s3-auth-form">
        <h2>Verify your email</h2>
        <p class="lede">Enter the 6-digit code sent to {{ $user->email }}. It is valid for 5 minutes.</p>
        @if (session('status'))<p class="s3-alert" role="status">{{ session('status') }}</p>@endif
        @if (session('email_verification_preview'))<p class="s3-alert" role="status">Email sending is not configured yet. Your code is <strong>{{ session('email_verification_preview') }}</strong>.</p>@endif
        @if (session('mail_error'))<p class="err" role="alert">{{ session('mail_error') }}</p>@endif
        @error('code')<p class="err" role="alert">{{ $message }}</p>@enderror
        <form method="post" action="{{ route('email.verify') }}">
            @csrf
            <div class="s3-field"><label for="verification-code">Verification code</label><input id="verification-code" name="code" value="{{ old('code') }}" inputmode="numeric" autocomplete="one-time-code" pattern="[0-9]{6}" minlength="6" maxlength="6" required></div>
            <p><button class="s3-btn" type="submit">Verify email</button></p>
        </form>
        <form method="post" action="{{ route('email.verify.resend') }}">@csrf<button class="s3-link" type="submit">Resend code</button></form>
    </div>
</section>
@endsection
