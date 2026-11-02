@extends('layouts.storefront')

@section('title', 'Reset password')
@section('crumb')
    <span>Reset password</span>
@endsection

@section('content')
<section class="s3-main s3-auth">
    <div class="s3-auth-art"><img src="{{ asset('images/storefront/login.svg') }}" alt=""></div>
    <div class="s3-auth-form">
        <h2>Choose a new password</h2>
        <p class="lede">Use at least 8 characters with mixed case and a number.</p>
        @if ($errors->any())<p class="err">{{ $errors->first() }}</p>@endif
        <form method="post" action="{{ route('password.update') }}">
            @csrf
            <input type="hidden" name="token" value="{{ $token }}">
            <div class="s3-field"><label for="reset-email">Email Address</label><input id="reset-email" type="email" name="email" value="{{ old('email', $email) }}" autocomplete="email" required></div>
            <div class="s3-field"><label for="reset-password">New password</label><input id="reset-password" type="password" name="password" autocomplete="new-password" required></div>
            <div class="s3-field"><label for="reset-password-confirm">Confirm password</label><input id="reset-password-confirm" type="password" name="password_confirmation" autocomplete="new-password" required></div>
            <p><button class="s3-btn" type="submit">Save password</button></p>
        </form>
    </div>
</section>
@endsection
