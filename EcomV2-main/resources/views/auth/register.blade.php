@extends('layouts.storefront')

@section('title', 'Sign up')
@section('crumb')
    <span>Sign up</span>
@endsection

@section('content')
<section class="s3-main s3-auth">
    <div class="s3-auth-art">
        <img src="{{ asset('images/storefront/login.svg') }}" alt="">
    </div>
    <div class="s3-auth-form">
        <h2>Sign up</h2>
        <p class="lede">Create a shopper account</p>
        @if ($errors->any())
            <p class="err">{{ $errors->first() }}</p>
        @endif
        <form method="post" action="{{ route('register') }}">
            @csrf
            <div class="s3-two">
                <div class="s3-field"><label for="register-first-name">First name</label><input id="register-first-name" name="first_name" value="{{ old('first_name') }}" autocomplete="given-name" minlength="2" maxlength="50" required></div>
                <div class="s3-field"><label for="register-last-name">Last name</label><input id="register-last-name" name="last_name" value="{{ old('last_name') }}" autocomplete="family-name" minlength="2" maxlength="50" required></div>
            </div>
            <div class="s3-field">
                <label>Email Address</label>
                <input type="email" name="email" value="{{ old('email') }}" placeholder="you@email.com" autocomplete="email" required>
            </div>
            <div class="s3-field">
                <label>Phone</label>
                <input name="phone" value="{{ old('phone') }}" placeholder="09XX XXX XXXX" autocomplete="tel" required>
            </div>
            <div class="s3-field"><label for="register-birthday">Date of birth</label><input id="register-birthday" type="date" name="birthday" value="{{ old('birthday') }}" max="{{ now()->subYears(18)->toDateString() }}" autocomplete="bday" required></div>
            <h3>Delivery address</h3>
            <div class="s3-field"><label for="register-street">Street address</label><input id="register-street" name="street_line" value="{{ old('street_line') }}" autocomplete="street-address" maxlength="255" required></div>
            @include('partials.philippine-location-picker', [
                'regionNameField' => 'region_name',
                'provinceNameField' => 'province_name',
                'cityNameField' => 'city_name',
                'barangayNameField' => 'barangay_name',
                'countryCodeField' => 'country_code',
                'countryNameField' => 'country_name',
                'postalCodeField' => 'postal_code',
                'initialCountryCode' => old('country_code', 'PH'),
                'initialCountryName' => old('country_name', 'Philippines'),
            ])
            <div class="s3-field">
                <label>Password</label>
                <input type="password" name="password" placeholder="Password" autocomplete="new-password" required>
            </div>
            <div class="s3-field">
                <label>Confirm Password</label>
                <input type="password" name="password_confirmation" placeholder="Confirm password" autocomplete="new-password" required>
            </div>
            <label class="register-terms"><input type="checkbox" name="terms" value="1" @checked(old('terms')) required> I agree to the JEAP Terms and Privacy Policy.</label>
            <p><button class="s3-btn" type="submit" style="min-width:163px;">Sign up</button></p>
            <div class="s3-auth-divider"><span>OR</span></div>
            <a class="s3-google-button" href="{{ route('google.redirect', ['from' => 'register']) }}">
                <svg aria-hidden="true" width="18" height="18" viewBox="0 0 48 48" focusable="false"><path fill="#4285F4" d="M43.6 24.5c0-1.4-.1-2.8-.4-4.1H24v7.8h11a9.4 9.4 0 0 1-4.1 6.2v5h6.6c3.9-3.6 6.1-8.8 6.1-14.9Z"/><path fill="#34A853" d="M24 44c5.5 0 10.1-1.8 13.5-4.8l-6.6-5c-1.8 1.2-4.1 2-6.9 2-5.3 0-9.8-3.6-11.4-8.4H5.8v5.2A20 20 0 0 0 24 44Z"/><path fill="#FBBC05" d="M12.6 27.8a12 12 0 0 1 0-7.6V15H5.8a20 20 0 0 0 0 18Z"/><path fill="#EA4335" d="M24 11.8c3 0 5.7 1 7.8 3.1l5.8-5.8C34.1 5.8 29.5 4 24 4A20 20 0 0 0 5.8 15l6.8 5.2c1.6-4.8 6.1-8.4 11.4-8.4Z"/></svg>
                <span>Continue with Google</span>
            </a>
            <p><a class="s3-link" href="{{ route('login') }}">Already have an account? Log in</a></p>
            <p class="s3-extra" style="border:0;padding-top:8px;">
                <a class="s3-link" href="{{ route('register.seller') }}">Sell on JEAP</a>
            </p>
        </form>
    </div>
</section>
@endsection
