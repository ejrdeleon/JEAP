@extends('layouts.storefront')

@section('title', 'Sorting center registration')
@section('crumb')
    <span>Sorting center registration</span>
@endsection

@section('content')
<section class="s3-main s3-auth">
    <div class="s3-auth-art"><img src="{{ asset('images/storefront/login.svg') }}" alt=""></div>
    <div class="s3-auth-form">
        <h2>Open a sorting center</h2>
        <p class="lede">Apply as JEAP logistics. Verify your email, then an admin will review your company.</p>
        @if ($errors->any())<p class="err" role="alert">{{ $errors->first() }}</p>@endif
        <form method="post" action="{{ route('register.logistics') }}" enctype="multipart/form-data">
            @csrf
            <div class="s3-field"><label for="logistics-company">Company name</label><input id="logistics-company" name="business_name" value="{{ old('business_name') }}" maxlength="160" required></div>
            <div class="s3-field"><label for="logistics-sec">SEC registration number</label><input id="logistics-sec" name="sec_registration_number" value="{{ old('sec_registration_number') }}" placeholder="CS202012345" pattern="[A-Za-z]{2}[0-9]{9}" required></div>
            <div class="s3-field"><label for="logistics-tin">TIN (000-000-000-000)</label><input id="logistics-tin" name="tin" value="{{ old('tin') }}" placeholder="234-567-890-000" inputmode="numeric" pattern="[0-9-]{12,15}" required></div>
            <h3>Primary contact</h3>
            <div class="s3-two"><div class="s3-field"><label for="logistics-first-name">First name</label><input id="logistics-first-name" name="first_name" value="{{ old('first_name') }}" minlength="2" maxlength="50" required></div><div class="s3-field"><label for="logistics-last-name">Last name</label><input id="logistics-last-name" name="last_name" value="{{ old('last_name') }}" minlength="2" maxlength="50" required></div></div>
            <div class="s3-field"><label for="logistics-position">Position</label><input id="logistics-position" name="contact_position" value="{{ old('contact_position') }}" maxlength="120" required></div>
            <div class="s3-field"><label for="logistics-email">Contact email</label><input id="logistics-email" type="email" name="email" value="{{ old('email') }}" autocomplete="email" required></div>
            <div class="s3-field"><label for="logistics-phone">Mobile number</label><input id="logistics-phone" type="tel" name="phone" value="{{ old('phone') }}" placeholder="09XX XXX XXXX or +639XX XXX XXXX" autocomplete="tel" required></div>
            <h3>Company address</h3>
            <div class="s3-field"><label for="logistics-street">Street address</label><input id="logistics-street" name="street_line" value="{{ old('street_line') }}" autocomplete="street-address" maxlength="255" required></div>
            @include('partials.philippine-location-picker', ['regionNameField' => 'region_name', 'provinceNameField' => 'province_name', 'cityNameField' => 'city_name', 'barangayNameField' => 'barangay_name', 'countryCodeField' => 'country_code', 'countryNameField' => 'country_name', 'postalCodeField' => 'postal_code', 'initialCountryCode' => 'PH', 'initialCountryName' => 'Philippines'])
            <div class="s3-field"><label for="service-areas">Service areas <span>Select one or more regions</span></label><select id="service-areas" name="service_areas[]" multiple size="6" required>@foreach (['National Capital Region (NCR)', 'Region I (Ilocos Region)', 'Region II (Cagayan Valley)', 'Region III (Central Luzon)', 'Region IV-A (CALABARZON)', 'MIMAROPA', 'Region V (Bicol Region)', 'Region VI (Western Visayas)', 'Region VII (Central Visayas)', 'Region VIII (Eastern Visayas)', 'Region IX (Zamboanga Peninsula)', 'Region X (Northern Mindanao)', 'Region XI (Davao Region)', 'Region XII (SOCCSKSARGEN)', 'Region XIII (Caraga)', 'Cordillera Administrative Region (CAR)', 'Bangsamoro Autonomous Region in Muslim Mindanao (BARMM)'] as $area)<option value="{{ $area }}" @selected(in_array($area, old('service_areas', []), true))>{{ $area }}</option>@endforeach</select></div>
            <fieldset class="seller-docs"><legend>Company documents <small>JPG, PNG or PDF · up to 5 MB each</small></legend>
                <div class="s3-field"><label for="logistics-sec-file">SEC certificate</label><input id="logistics-sec-file" type="file" name="documents[sec_certificate]" accept=".jpg,.jpeg,.png,.pdf" required></div>
                <div class="s3-field"><label for="logistics-bir-file">BIR Form 2303</label><input id="logistics-bir-file" type="file" name="documents[bir_2303]" accept=".jpg,.jpeg,.png,.pdf" required></div>
                <div class="s3-field"><label for="logistics-permit">Mayor’s / business permit</label><input id="logistics-permit" type="file" name="documents[business_permit]" accept=".jpg,.jpeg,.png,.pdf" required></div>
                <div class="s3-field"><label for="logistics-id">Valid ID of authorized representative</label><input id="logistics-id" type="file" name="documents[representative_id]" accept=".jpg,.jpeg,.png,.pdf" required></div>
            </fieldset>
            <div class="s3-field"><label for="logistics-password">Password</label><input id="logistics-password" type="password" name="password" minlength="8" autocomplete="new-password" required></div>
            <div class="s3-field"><label for="logistics-password-confirm">Confirm password</label><input id="logistics-password-confirm" type="password" name="password_confirmation" minlength="8" autocomplete="new-password" required></div>
            <label class="register-terms"><input type="checkbox" name="terms" value="1" @checked(old('terms')) required> I agree to the JEAP Terms and Privacy Policy.</label>
            <p><button class="s3-btn" type="submit">Apply as logistics</button></p>
            <p><a class="s3-link" href="{{ route('login') }}">Already have an account? Log in</a></p>
            <p><a class="s3-link" href="{{ route('register.seller') }}">Sell on JEAP</a></p>
        </form>
    </div>
</section>
@endsection
