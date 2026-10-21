@extends('layouts.storefront')

@section('title', 'Checkout')
@section('crumb')
                <a href="{{ route('products.index') }}">shop</a>
    <span>/</span>
    <span>checkout</span>
@endsection

@section('content')
@php
    $items = $cart?->items ?? collect();
    $merchandise = $items->sum(fn ($i) => $i->unit_price * $i->quantity);
    $shippingFee = $shippingFee ?? \App\Commerce\InventoryPolicy::shippingFee();
    $total = $merchandise + $shippingFee;
    $defaultAddress = $addresses->firstWhere('is_default', true) ?? $addresses->first();
    $selectedAddressId = (string) old('address_id', $defaultAddress?->id ?? '');
    $selectedAddress = $addresses->firstWhere('id', (int) $selectedAddressId);
@endphp
<section class="s3-main">
    <h3 style="padding:48px 48px 0;margin:0;">checkout</h3>
    @if ($errors->any())
        <div class="s3-alert" role="alert" aria-live="polite">{{ $errors->first() }}</div>
    @endif
    <div class="s3-check">
        <div>
            <div class="s3-alert">
                @guest Returning customer? <a href="{{ route('login') }}">Click here to log in</a>
                @else Signed in as {{ auth()->user()->email }}
                @endguest
            </div>
            <form id="checkout-form" method="post" action="{{ route('checkout.place') }}">
                @csrf
                <h3>Billing Detail</h3>
                @if ($addresses->isNotEmpty())
                    <div class="s3-field">
                        <label for="address_id">Delivery address</label>
                        <select id="address_id" name="address_id" data-address-choice>
                            <option value="">Enter a new delivery address</option>
                            @foreach ($addresses as $address)
                                <option value="{{ $address->id }}"
                                    data-recipient="{{ $address->recipient_name }}"
                                    data-phone="{{ $address->phone }}"
                                    data-street="{{ $address->street_line }}"
                                    data-region-code="{{ $address->region_code }}"
                                    data-province-code="{{ $address->province_code }}"
                                    data-city-code="{{ $address->city_code }}"
                                    data-barangay-code="{{ $address->barangay_code }}"
                                    data-region-name="{{ $address->region_name }}"
                                    data-country-code="{{ $address->country_code ?: 'PH' }}"
                                    data-country-name="{{ $address->country_name ?: 'Philippines' }}"
                                    data-city="{{ $address->city_name }}"
                                    data-province="{{ $address->province_name }}"
                                    data-barangay="{{ $address->barangay_name }}"
                                    data-zip="{{ $address->postal_code }}"
                                    data-latitude="{{ $address->latitude }}"
                                    data-longitude="{{ $address->longitude }}"
                                    @selected($selectedAddressId === (string) $address->id)>
                                    {{ $address->label ?: 'Delivery address' }} — {{ $address->street_line }}, {{ $address->barangay_name ? $address->barangay_name.', ' : '' }}{{ $address->city_name }}{{ $address->is_default ? ' (default)' : '' }}
                                </option>
                            @endforeach
                        </select>
                    </div>
                @else
                    <input type="hidden" name="address_id" value="">
                @endif
                <fieldset class="delivery-address-entry" data-address-entry @if ($selectedAddress) hidden disabled @endif>
                <div class="s3-two">
                    <div class="s3-field"><label for="first_name">First Name</label><input id="first_name" name="first_name" data-address-entry-field value="{{ old('first_name', auth()->user()->first_name ?? '') }}" autocomplete="given-name" required></div>
                    <div class="s3-field"><label for="last_name">Last Name</label><input id="last_name" name="last_name" data-address-entry-field value="{{ old('last_name', auth()->user()->last_name ?? '') }}" autocomplete="family-name" required></div>
                </div>
                <div class="s3-field"><label>Company Name (optional)</label><input name="company"></div>
                <div class="s3-field"><label for="street">Street Address</label><input id="street" name="street" data-address-entry-field value="{{ old('street') }}" autocomplete="address-line1" placeholder="House number and street name ..." required></div>
                <div class="s3-field"><label class="sr-only" for="street2">Apartment, suite, or unit (optional)</label><input id="street2" name="street2" data-address-entry-field value="{{ old('street2') }}" autocomplete="address-line2" placeholder="Apartment, suite, unit, etc (Optional)"></div>
                @include('partials.philippine-location-picker', [
                    'regionNameField' => 'region_name',
                    'provinceNameField' => 'province',
                    'cityNameField' => 'city',
                    'barangayNameField' => 'barangay',
                    'countryNameField' => 'country',
                    'postalCodeField' => 'zip',
                    'initialCountryCode' => old('country_code', 'PH'),
                    'initialCountryName' => old('country', 'Philippines'),
                    'initialPostalCode' => old('zip', ''),
                    'initialRegionName' => old('region_name', ''),
                    'initialProvinceName' => old('province', ''),
                    'initialCityName' => old('city', ''),
                    'initialBarangayName' => old('barangay', ''),
                    'initialRegionCode' => old('region_code', ''),
                    'initialProvinceCode' => old('province_code', ''),
                    'initialCityCode' => old('city_code', ''),
                    'initialBarangayCode' => old('barangay_code', ''),
                ])
                <div class="s3-field"><label for="phone">Phone Number</label><input id="phone" name="phone" data-address-entry-field value="{{ old('phone', auth()->user()->phone ?? '') }}" autocomplete="tel" required></div>
                </fieldset>
                <div class="s3-field"><label for="email">Email Address</label><input id="email" type="email" name="email" value="{{ old('email', auth()->user()->email ?? '') }}" autocomplete="email" required></div>
                <input type="hidden" name="latitude" value="{{ old('latitude', $selectedAddress?->latitude) }}">
                <input type="hidden" name="longitude" value="{{ old('longitude', $selectedAddress?->longitude) }}">
                @include('partials.delivery-map-picker', [
                    'mapsKey' => $mapsKey,
                    'addressSelector' => 'address_id',
                    'latitudeField' => 'latitude',
                    'longitudeField' => 'longitude',
                ])
                <h3>Additional Information</h3>
                <div class="s3-field">
                    <label>Order Notes (optional)</label>
                    <textarea name="notes" placeholder="Note about your order, e.g. special note for delivery"></textarea>
                </div>
                <input type="hidden" name="gateway" value="cod">
            </form>
        </div>
        <aside>
            <h3>Your Order</h3>
            <div class="s3-ordercard">
                <div class="s3-line"><span>Product</span><span>sub total</span></div>
                @forelse($items as $item)
                    <div class="s3-line" style="align-items:flex-start;">
                        <div style="display:flex;gap:12px;">
                            @if($item->variant?->product?->primaryImage())
                                <img src="{{ asset($item->variant->product->primaryImage()->path) }}" alt="" width="60" height="60" style="object-fit:contain;background:#f7f7fb;">
                            @endif
                            <div>
                                {{ $item->variant?->product?->name }}<br>
                                <small>x {{ $item->quantity }}</small>
                            </div>
                        </div>
                        <strong>₱{{ number_format($item->unit_price * $item->quantity, 2) }}</strong>
                    </div>
                @empty
                    <p>Cart is empty.</p>
                @endforelse
                <p>Merchandise <span style="float:right;">₱{{ number_format($merchandise, 2) }}</span></p>
                <p>Standard shipping <span style="float:right;">₱{{ number_format($shippingFee, 2) }}</span></p>
                <div class="s3-line" style="border:0;"><strong>Order Total</strong><strong>₱{{ number_format($total, 2) }}</strong></div>
            </div>
            <div class="s3-paymethods">
                <label><input type="radio" name="pay_ui" checked> Cash on Delivery</label>
                <button class="s3-btn wide" type="submit" form="checkout-form" @disabled($items->isEmpty())>place order</button>
            </div>
        </aside>
    </div>
</section>
@endsection
