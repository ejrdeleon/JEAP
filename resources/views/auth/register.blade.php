@extends('layouts.storefront')

@section('title', 'Sign up')
@section('crumb')
    <span>Sign up</span>
@endsection

@section('content')
<section class="s3-main auth-shell">
    <aside class="auth-aside">
        <p class="status-kicker">Shopper</p>
        <h1>Create your JEAP account</h1>
        <p>Save addresses, follow shops, and place Cash on Delivery orders.</p>
        <ul class="auth-perks">
            <li>Cash on Delivery</li>
            <li>₱{{ number_format(config('jeap.shipping_fee'), 0) }} shipping</li>
            <li>Track with {{ config('jeap.courier_name') }}</li>
        </ul>
        <img src="{{ asset('images/storefront/login.svg') }}" alt="">
    </aside>
    <div class="auth-card">
        <h2>Sign up</h2>
        <p class="lede">You must be 18 or older. Add a Philippine delivery address so you can check out.</p>
        @if ($errors->any())
            <p class="err">{{ $errors->first() }}</p>
        @endif
        <form method="post" action="{{ route('register') }}">
            @csrf
            <section class="auth-block">
                <h3>Your details</h3>
                <div class="s3-two">
                    <div class="s3-field"><label for="register-first-name">First name</label><input id="register-first-name" name="first_name" value="{{ old('first_name') }}" autocomplete="given-name" minlength="2" maxlength="50" required></div>
                    <div class="s3-field"><label for="register-last-name">Last name</label><input id="register-last-name" name="last_name" value="{{ old('last_name') }}" autocomplete="family-name" minlength="2" maxlength="50" required></div>
                </div>
                <div class="s3-field">
                    <label for="register-email">Email address</label>
                    <input id="register-email" type="email" name="email" value="{{ old('email') }}" placeholder="you@email.com" autocomplete="email" required>
                </div>
                <div class="s3-field">
                    <label for="register-phone">Phone</label>
                    <input id="register-phone" name="phone" value="{{ old('phone') }}" placeholder="09XX XXX XXXX" autocomplete="tel" required>
                </div>
                <div class="s3-field"><label for="register-birthday">Date of birth</label><input id="register-birthday" type="date" name="birthday" value="{{ old('birthday') }}" max="{{ now()->subYears(18)->toDateString() }}" autocomplete="bday" required></div>
            </section>
            <section class="auth-block">
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
            </section>
            <section class="auth-block">
                <h3>Password</h3>
                <div class="s3-field">
                    <label for="register-password">Password</label>
                    <input id="register-password" type="password" name="password" placeholder="Password" autocomplete="new-password" required>
                </div>
                <div class="s3-field">
                    <label for="register-password-confirm">Confirm password</label>
                    <input id="register-password-confirm" type="password" name="password_confirmation" placeholder="Confirm password" autocomplete="new-password" required>
                </div>
            </section>
            <label class="register-terms"><input type="checkbox" name="terms" value="1" @checked(old('terms')) required> I agree to the JEAP <a href="{{ route('policies.show', 'terms') }}">Terms</a> and <a href="{{ route('policies.show', 'privacy') }}">Privacy Policy</a>.</label>
            <button class="auth-submit" type="submit">Sign up</button>
            <div class="s3-auth-divider"><span>OR</span></div>
            @include('partials.google-auth-button', ['from' => 'register'])
            <div class="auth-links">
                <a href="{{ route('login') }}">Already have an account? Log in</a>
                <a href="{{ route('register.seller') }}">Sell on JEAP</a>
            </div>
        </form>
    </div>
</section>
@endsection
