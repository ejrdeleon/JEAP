@extends('layouts.storefront')

@section('title', 'Seller registration')
@section('crumb')
    <span>Seller registration</span>
@endsection

@section('content')
@php
    $existingBuyer = $existingBuyer ?? null;
    $buyerAddress = $buyerAddress ?? null;
    $useSame = old('use_same_address', $buyerAddress ? '1' : '0') === '1';
@endphp
<section class="s3-main s3-auth">
    <div class="s3-auth-art"><img src="{{ asset('images/storefront/login.svg') }}" alt=""></div>
    <div class="s3-auth-form">
        <h2>Sell on JEAP</h2>
        <p class="lede">{{ $existingBuyer ? 'Use your shopper account to open a shop. Your delivery address can be reused as the shop pickup address.' : 'Apply as a seller. Verify your email, then an admin will review your shop.' }}</p>
        @if ($errors->any())<p class="err" role="alert">{{ $errors->first() }}</p>@endif
        <form method="post" action="{{ route('register.seller') }}" enctype="multipart/form-data">
            @csrf
            @if($existingBuyer)
                <p class="seller-existing-note">Applying as {{ $existingBuyer->name }} · {{ $existingBuyer->email }}</p>
            @else
                <div class="s3-two"><div class="s3-field"><label for="seller-first-name">First name</label><input id="seller-first-name" name="first_name" value="{{ old('first_name') }}" minlength="2" maxlength="50" autocomplete="given-name" required></div><div class="s3-field"><label for="seller-last-name">Last name</label><input id="seller-last-name" name="last_name" value="{{ old('last_name') }}" minlength="2" maxlength="50" autocomplete="family-name" required></div></div>
            @endif
            <div class="s3-field"><label for="seller-shop-name">Shop name</label><input id="seller-shop-name" name="business_name" value="{{ old('business_name') }}" minlength="3" maxlength="30" required></div>
            <div class="s3-field"><label for="seller-category">Shop category</label><select id="seller-category" name="shop_category_id" required><option value="">Choose a category</option>@foreach ($categories as $category)<option value="{{ $category->id }}" @selected((string) old('shop_category_id') === (string) $category->id)>{{ $category->name }}</option>@endforeach</select></div>
            <div class="s3-field"><label for="seller-type">Seller type</label><select id="seller-type" name="seller_type" required><option value="">Choose seller type</option><option value="individual" @selected(old('seller_type') === 'individual')>Individual</option><option value="sole_proprietorship" @selected(old('seller_type') === 'sole_proprietorship')>Sole proprietorship</option><option value="corporation" @selected(old('seller_type') === 'corporation')>Corporation</option></select></div>
            <div class="s3-field"><label for="seller-tin">TIN (000-000-000-000)</label><input id="seller-tin" name="tin" value="{{ old('tin') }}" inputmode="numeric" placeholder="123-456-789-000" pattern="[0-9-]{12,15}" required></div>
            <div class="s3-field seller-sec-field" @if(old('seller_type') !== 'corporation') hidden @endif><label for="seller-sec">SEC registration number</label><input id="seller-sec" name="sec_registration_number" value="{{ old('sec_registration_number') }}" placeholder="CS202012345" pattern="[A-Za-z]{2}[0-9]{9}" @required(old('seller_type') === 'corporation')></div>
            @unless($existingBuyer)
                <div class="s3-field"><label for="seller-email">Email address</label><input id="seller-email" type="email" name="email" value="{{ old('email') }}" autocomplete="email" required></div>
                <div class="s3-field"><label for="seller-phone">Mobile number</label><input id="seller-phone" type="tel" name="phone" value="{{ old('phone') }}" placeholder="09XX XXX XXXX or +639XX XXX XXXX" autocomplete="tel" required></div>
            @endunless
            <fieldset class="seller-docs"><legend>Business documents <small>JPG, PNG or PDF · up to 5 MB each</small></legend>
                <div class="s3-field"><label for="seller-id">Government-issued ID</label><input id="seller-id" type="file" name="documents[government_id]" accept=".jpg,.jpeg,.png,.pdf" required></div>
                <div class="s3-field seller-dti-field" @if(!in_array(old('seller_type'), ['sole_proprietorship', 'corporation'], true)) hidden @endif><label for="seller-dti">DTI certificate <span>(sole proprietorship)</span></label><input id="seller-dti" type="file" name="documents[dti_certificate]" accept=".jpg,.jpeg,.png,.pdf" @required(old('seller_type') === 'sole_proprietorship')></div>
                <div class="s3-field seller-sec-doc-field" @if(old('seller_type') !== 'corporation') hidden @endif><label for="seller-sec-file">SEC certificate <span>(corporation)</span></label><input id="seller-sec-file" type="file" name="documents[sec_certificate]" accept=".jpg,.jpeg,.png,.pdf" @required(old('seller_type') === 'corporation')></div>
                <div class="s3-field seller-bir-field" @if(!in_array(old('seller_type'), ['sole_proprietorship', 'corporation'], true)) hidden @endif><label for="seller-bir">BIR Form 2303</label><input id="seller-bir" type="file" name="documents[bir_2303]" accept=".jpg,.jpeg,.png,.pdf" @required(in_array(old('seller_type'), ['sole_proprietorship', 'corporation'], true))></div>
            </fieldset>
            @if($buyerAddress)
                <label class="register-terms"><input type="checkbox" name="use_same_address" value="1" id="use-same-address" @checked($useSame)> Use the same address as my delivery address</label>
                <p class="seller-existing-note" id="same-address-preview">{{ $buyerAddress->street_line }}, {{ collect([$buyerAddress->barangay_name, $buyerAddress->city_name, $buyerAddress->province_name, $buyerAddress->postal_code])->filter()->implode(', ') }}</p>
            @endif
            <div id="seller-address-fields" @if($buyerAddress && $useSame) hidden @endif>
                <h3>Your address</h3>
                <p class="lede">JEAP will use this as the shop pickup address.</p>
                <div class="s3-field"><label for="seller-street">Street address</label><input id="seller-street" name="street_line" value="{{ old('street_line') }}" autocomplete="street-address" maxlength="255" @required(!($buyerAddress && $useSame))></div>
                @include('partials.philippine-location-picker', ['regionNameField' => 'region_name', 'provinceNameField' => 'province_name', 'cityNameField' => 'city_name', 'barangayNameField' => 'barangay_name', 'countryCodeField' => 'country_code', 'countryNameField' => 'country_name', 'postalCodeField' => 'postal_code', 'initialCountryCode' => 'PH', 'initialCountryName' => 'Philippines'])
            </div>
            @unless($existingBuyer)
                <div class="s3-field"><label for="seller-password">Password</label><input id="seller-password" type="password" name="password" minlength="8" autocomplete="new-password" required></div>
                <div class="s3-field"><label for="seller-password-confirm">Confirm password</label><input id="seller-password-confirm" type="password" name="password_confirmation" minlength="8" autocomplete="new-password" required></div>
            @endunless
            <label class="register-terms"><input type="checkbox" name="terms" value="1" @checked(old('terms')) required> I agree to the JEAP Terms and Privacy Policy.</label>
            <p><button class="s3-btn" type="submit">{{ $existingBuyer ? 'Submit shop' : 'Apply as seller' }}</button></p>
            <p><a class="s3-link" href="{{ route('login') }}">Already have an account? Log in</a></p>
            <p><a class="s3-link" href="{{ route('register') }}">Shopper registration</a></p>
        </form>
    </div>
</section>
<script>
    const sellerType = document.querySelector('#seller-type');
    sellerType?.addEventListener('change', () => {
        const type = sellerType.value;
        const toggle = (selector, visible, requiredSelector = 'input') => {
            const wrapper = document.querySelector(selector);
            if (!wrapper) return;
            wrapper.hidden = !visible;
            const field = wrapper.querySelector(requiredSelector);
            if (field) field.required = visible;
        };
        toggle('.seller-sec-field', type === 'corporation');
        toggle('.seller-dti-field', type === 'sole_proprietorship');
        toggle('.seller-sec-doc-field', type === 'corporation');
        toggle('.seller-bir-field', ['sole_proprietorship', 'corporation'].includes(type));
    });
    const useSame = document.querySelector('#use-same-address');
    const addressFields = document.querySelector('#seller-address-fields');
    const preview = document.querySelector('#same-address-preview');
    const syncAddress = () => {
        const same = Boolean(useSame?.checked);
        if (addressFields) addressFields.hidden = same;
        if (preview) preview.hidden = !same;
        addressFields?.querySelectorAll('input, select').forEach((field) => {
            if (field.type === 'hidden') return;
            field.required = !same && ['street_line', 'region_name', 'city_name', 'postal_code'].includes(field.name);
            field.disabled = same;
        });
    };
    useSame?.addEventListener('change', syncAddress);
    syncAddress();
</script>
@endsection
