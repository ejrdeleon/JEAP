@extends('layouts.storefront')
@section('title', 'Activate rider account')
@section('crumb')<span>Rider activation</span>@endsection
@section('content')
<section class="s3-main s3-auth">
    <div class="s3-auth-art"><img src="{{ asset('images/storefront/login.svg') }}" alt=""></div>
    <div class="s3-auth-form">
        <h2>Activate your rider account</h2>
        <p class="lede">Set a password to activate the rider account created for {{ $user->name }}.</p>
        @if ($errors->any())<p class="err" role="alert">{{ $errors->first() }}</p>@endif
        <form method="post" action="{{ route('rider.activate', ['user' => $user->id, 'token' => $token]) }}">
            @csrf
            <div class="s3-field"><label for="rider-password">Password</label><input id="rider-password" type="password" name="password" minlength="8" autocomplete="new-password" required></div>
            <div class="s3-field"><label for="rider-password-confirm">Confirm password</label><input id="rider-password-confirm" type="password" name="password_confirmation" minlength="8" autocomplete="new-password" required></div>
            <p><button class="s3-btn" type="submit">Activate account</button></p>
        </form>
    </div>
</section>
@endsection
