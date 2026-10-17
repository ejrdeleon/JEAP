@extends('layouts.storefront')

@section('title', 'Rider registration')
@section('crumb')
    <span>Rider registration</span>
@endsection

@section('content')
<section class="s3-main s3-auth">
    <div class="s3-auth-art">
        <img src="{{ asset('images/storefront/login.svg') }}" alt="">
    </div>
    <div class="s3-auth-form">
        <h2>Become a rider</h2>
        <p class="lede">Apply as a JEAP rider. The sorting center reviews you before you can log in.</p>
        @if ($errors->any())
            <p class="err">{{ $errors->first() }}</p>
        @endif
        <form method="post" action="{{ route('register.rider') }}" enctype="multipart/form-data">
            @csrf
            <div class="s3-field">
                <label>Your name</label>
                <input name="name" value="{{ old('name') }}" placeholder="Jhon Deo" required>
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
                <label>Vehicle type</label>
                <input name="vehicle_type" value="{{ old('vehicle_type') }}" placeholder="Motorcycle" required>
            </div>
            <div class="s3-field">
                <label>Plate number</label>
                <input name="plate_number" value="{{ old('plate_number') }}" placeholder="ABC 1234" required>
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
                <label>Driver's license / KYC document</label>
                <input type="file" name="kyc" accept=".jpg,.jpeg,.png,.pdf" required>
            </div>
            <p><button class="s3-btn" type="submit" style="min-width:163px;">Apply as rider</button></p>
            <p><a class="s3-link" href="{{ route('login') }}">already user ? Login</a></p>
            <p class="s3-extra" style="border:0;padding-top:8px;">
                <a class="s3-link" href="{{ route('register') }}">Shopper registration</a>
                &nbsp;·&nbsp;
                <a class="s3-link" href="{{ route('register.seller') }}">Sell on JEAP</a>
                &nbsp;·&nbsp;
                <a class="s3-link" href="{{ route('register.logistics') }}">Sorting center</a>
            </p>
        </form>
    </div>
</section>
@endsection
