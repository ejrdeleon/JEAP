@extends('layouts.storefront')

@section('title', 'Seller registration')
@section('crumb')
    <span>Seller registration</span>
@endsection

@section('content')
<section class="s3-main s3-auth">
    <div class="s3-auth-art">
        <img src="{{ asset('images/storefront/login.svg') }}" alt="">
    </div>
    <div class="s3-auth-form">
        <h2>Sell on JEAP</h2>
        <p class="lede">Apply as a seller. Admin reviews your shop before you can log in.</p>
        @if ($errors->any())
            <p class="err">{{ $errors->first() }}</p>
        @endif
        <form method="post" action="{{ route('register.seller') }}" enctype="multipart/form-data">
            @csrf
            <div class="s3-field">
                <label>Your name</label>
                <input name="name" value="{{ old('name') }}" placeholder="Jhon Deo" required>
            </div>
            <div class="s3-field">
                <label>Shop / business name</label>
                <input name="business_name" value="{{ old('business_name') }}" placeholder="JEAP Gadgets" required>
            </div>
            <div class="s3-field">
                <label>Email Address</label>
                <input type="email" name="email" value="{{ old('email') }}" placeholder="Example@gmail.com" required>
            </div>
            <div class="s3-field">
                <label>Phone</label>
                <input name="phone" value="{{ old('phone') }}" placeholder="09XX XXX XXXX">
            </div>
            <div class="s3-field">
                <label>Password</label>
                <input type="password" name="password" placeholder="...." required>
            </div>
            <div class="s3-field">
                <label>Confirm Password</label>
                <input type="password" name="password_confirmation" placeholder="...." required>
            </div>
            <div class="s3-field">
                <label>Business permit / KYC document</label>
                <input type="file" name="kyc" accept=".jpg,.jpeg,.png,.pdf" required>
            </div>
            <p><button class="s3-btn" type="submit" style="min-width:163px;">Apply as seller</button></p>
            <p><a class="s3-link" href="{{ route('login') }}">already user ? Login</a></p>
            <p class="s3-extra" style="border:0;padding-top:8px;">
                <a class="s3-link" href="{{ route('register') }}">Shopper registration</a>
                &nbsp;·&nbsp;
                <a class="s3-link" href="{{ route('register.rider') }}">Become a rider</a>
                &nbsp;·&nbsp;
                <a class="s3-link" href="{{ route('register.logistics') }}">Sorting center</a>
            </p>
        </form>
    </div>
</section>
@endsection
