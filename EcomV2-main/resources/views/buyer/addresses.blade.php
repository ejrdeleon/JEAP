@extends('layouts.storefront')
@section('title', 'Delivery addresses')
@section('content')
<section class="storefront-pad delivery-address-page">
    <header class="delivery-address-heading">
        <div><span class="delivery-eyebrow">YOUR ACCOUNT</span><h1>Delivery addresses</h1><p>Save a delivery location and move the pin to the exact drop-off point.</p></div>
        <a class="delivery-text-link" href="{{ route('checkout') }}">Continue to checkout</a>
    </header>
    @if (session('toast')) <p class="delivery-notice">{{ session('toast') }}</p> @endif
    @if ($errors->any()) <p class="delivery-error" role="alert">{{ $errors->first() }}</p> @endif

    <section class="delivery-address-panel">
        <h2>Add an address</h2>
        <form method="post" action="{{ route('buyer.addresses.store') }}" class="delivery-address-form">
            @csrf
            <div class="delivery-address-fields">
                <label class="delivery-field"><span>Label</span><input name="label" maxlength="64" value="{{ old('label') }}" placeholder="Home, work, etc."></label>
                <label class="delivery-field"><span>Recipient name</span><input name="recipient_name" maxlength="255" value="{{ old('recipient_name', auth()->user()->name) }}" required autocomplete="name"></label>
                <label class="delivery-field"><span>Phone</span><input name="phone" maxlength="32" value="{{ old('phone', auth()->user()->phone) }}" required autocomplete="tel"></label>
                <label class="delivery-field delivery-field-wide"><span>Street address / building</span><input name="street_line" maxlength="255" value="{{ old('street_line') }}" required autocomplete="street-address"></label>
                @include('partials.philippine-location-picker', [
                    'initialRegionName' => old('region_name', ''),
                    'initialCountryCode' => old('country_code', 'PH'),
                    'initialCountryName' => old('country_name', 'Philippines'),
                    'initialPostalCode' => old('postal_code', ''),
                    'initialProvinceName' => old('province_name', ''),
                    'initialCityName' => old('city_name', ''),
                    'initialBarangayName' => old('barangay_name', ''),
                    'initialRegionCode' => old('region_code', ''),
                    'initialProvinceCode' => old('province_code', ''),
                    'initialCityCode' => old('city_code', ''),
                    'initialBarangayCode' => old('barangay_code', ''),
                ])
            </div>
            <input type="hidden" name="latitude" value="{{ old('latitude') }}">
            <input type="hidden" name="longitude" value="{{ old('longitude') }}">
            @include('partials.delivery-map-picker', ['mapsKey' => $mapsKey])
            <label class="delivery-default-check"><input type="checkbox" name="is_default" value="1" @checked(old('is_default'))> Make this my default delivery address</label>
            <button class="delivery-submit" type="submit">Save address</button>
        </form>
    </section>

    <section class="delivery-saved-addresses" aria-labelledby="saved-addresses-heading">
        <h2 id="saved-addresses-heading">Saved addresses</h2>
        @forelse ($addresses as $address)
            <article class="delivery-saved-card">
                <div class="delivery-saved-card-heading">
                    <div><h3>{{ $address->label ?: 'Delivery address' }} @if ($address->is_default)<span class="delivery-default-pill">Default</span>@endif</h3>
                        <p>{{ $address->recipient_name }} · {{ $address->phone }}</p>
                    </div>
                    <details class="delivery-edit-details">
                        <summary>Edit address</summary>
                        <form method="post" action="{{ route('buyer.addresses.update', $address) }}" class="delivery-address-form delivery-edit-form">
                            @csrf @method('PUT')
                            <div class="delivery-address-fields">
                                <label class="delivery-field"><span>Label</span><input name="label" maxlength="64" value="{{ $address->label }}"></label>
                                <label class="delivery-field"><span>Recipient name</span><input name="recipient_name" maxlength="255" value="{{ $address->recipient_name }}" required autocomplete="name"></label>
                                <label class="delivery-field"><span>Phone</span><input name="phone" maxlength="32" value="{{ $address->phone }}" required autocomplete="tel"></label>
                                <label class="delivery-field delivery-field-wide"><span>Street address / building</span><input name="street_line" maxlength="255" value="{{ $address->street_line }}" required autocomplete="street-address"></label>
                                @include('partials.philippine-location-picker', [
                                    'initialRegionName' => $address->region_name,
                                    'initialCountryCode' => $address->country_code ?: 'PH',
                                    'initialCountryName' => $address->country_name ?: 'Philippines',
                                    'initialPostalCode' => $address->postal_code,
                                    'initialProvinceName' => $address->province_name,
                                    'initialCityName' => $address->city_name,
                                    'initialBarangayName' => $address->barangay_name,
                                    'initialRegionCode' => $address->region_code,
                                    'initialProvinceCode' => $address->province_code,
                                    'initialCityCode' => $address->city_code,
                                    'initialBarangayCode' => $address->barangay_code,
                                ])
                            </div>
                            <input type="hidden" name="latitude" value="{{ $address->latitude }}">
                            <input type="hidden" name="longitude" value="{{ $address->longitude }}">
                            @include('partials.delivery-map-picker', ['mapsKey' => $mapsKey])
                            <label class="delivery-default-check"><input type="checkbox" name="is_default" value="1" @checked($address->is_default)> Make this my default delivery address</label>
                            <button class="delivery-submit" type="submit">Save changes</button>
                        </form>
                        <form method="post" action="{{ route('buyer.addresses.delete', $address) }}" class="delivery-delete-form" onsubmit="return confirm('Remove this delivery address?')">
                            @csrf @method('DELETE')
                            <button class="delivery-delete-button" type="submit">Remove address</button>
                        </form>
                    </details>
                </div>
                <p class="delivery-saved-location">
                    {{ $address->street_line }}
                    @if ($address->barangay_name), {{ $address->barangay_name }}@endif
                    @if ($address->city_name), {{ $address->city_name }}@endif
                    @if ($address->province_name), {{ $address->province_name }}@endif
                    @if ($address->region_name && $address->region_name !== 'Philippines'), {{ $address->region_name }}@endif
                    @if ($address->postal_code) {{ $address->postal_code }}@endif
                </p>
                @if ($address->latitude !== null && $address->longitude !== null)
                    <p class="delivery-saved-coordinates">Pin: {{ $address->latitude }}, {{ $address->longitude }}</p>
                @endif
            </article>
        @empty
            <p class="delivery-empty">No saved addresses yet. Add your first delivery location above.</p>
        @endforelse
    </section>
</section>
@endsection
