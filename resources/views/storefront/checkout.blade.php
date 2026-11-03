@extends('layouts.storefront')

@section('title', 'Checkout')
@section('crumb')
    <a href="{{ route('products.index') }}">Shop</a>
    <span>/</span>
    <span>Checkout</span>
@endsection

@section('content')
@php
    $items = $cart?->items ?? collect();
    $merchandise = $items->sum(fn ($i) => $i->unit_price * $i->quantity);
    $shippingFee = $shippingFee ?? \App\Commerce\InventoryPolicy::shippingFee();
    $total = $merchandise + $shippingFee;
    $voucherCode = old('voucher_code');
    $defaultAddress = $addresses->firstWhere('is_default', true) ?? $addresses->first();
    $selectedAddressId = (string) old('address_id', $defaultAddress?->id ?? '');
    $selectedAddress = $addresses->firstWhere('id', (int) $selectedAddressId);
    $itemCount = $items->sum('quantity');
@endphp
<section class="s3-main check-page">
    @if ($errors->any())
        <div class="s3-alert check-alert" role="alert" aria-live="polite">{{ $errors->first() }}</div>
    @endif

    <div class="check-layout">
        <div class="check-main">
            <header class="check-heading">
                <div>
                    <p class="status-kicker">Checkout</p>
                    <h1>Place your order</h1>
                    <p>Cash on Delivery · ₱{{ number_format($shippingFee, 0) }} shipping · {{ config('jeap.courier_name') }}</p>
                </div>
                <a href="{{ route('cart.index') }}">Back to cart</a>
            </header>
            <div class="check-banner">
                @guest
                    Returning customer? <a href="{{ route('login') }}">Log in</a> to use saved addresses.
                @else
                    Signed in as <strong>{{ auth()->user()->email }}</strong>
                @endguest
            </div>

            <form id="checkout-form" method="post" action="{{ route('checkout.place') }}">
                @csrf
                <section class="check-card">
                    <h2>Delivery</h2>
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
                        <p class="check-help"><a href="{{ route('buyer.addresses') }}">Manage delivery addresses</a></p>
                    @else
                        <input type="hidden" name="address_id" value="">
                    @endif
                    <fieldset class="delivery-address-entry" data-address-entry @if ($selectedAddress) hidden disabled @endif>
                        <div class="s3-two">
                            <div class="s3-field"><label for="first_name">First name</label><input id="first_name" name="first_name" data-address-entry-field value="{{ old('first_name', auth()->user()->first_name ?? '') }}" autocomplete="given-name" required></div>
                            <div class="s3-field"><label for="last_name">Last name</label><input id="last_name" name="last_name" data-address-entry-field value="{{ old('last_name', auth()->user()->last_name ?? '') }}" autocomplete="family-name" required></div>
                        </div>
                        <div class="s3-field"><label>Company name (optional)</label><input name="company"></div>
                        <div class="s3-field"><label for="street">Street address</label><input id="street" name="street" data-address-entry-field value="{{ old('street') }}" autocomplete="address-line1" placeholder="House number and street name" required></div>
                        <div class="s3-field"><label class="sr-only" for="street2">Apartment, suite, or unit (optional)</label><input id="street2" name="street2" data-address-entry-field value="{{ old('street2') }}" autocomplete="address-line2" placeholder="Apartment, suite, unit (optional)"></div>
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
                        <div class="s3-field"><label for="phone">Phone number</label><input id="phone" name="phone" data-address-entry-field value="{{ old('phone', auth()->user()->phone ?? '') }}" autocomplete="tel" required></div>
                    </fieldset>
                    <div class="s3-field check-field-last">
                        <label for="email">Email address</label>
                        <input id="email" type="email" name="email" value="{{ old('email', auth()->user()->email ?? '') }}" autocomplete="email" required>
                    </div>
                    <input type="hidden" name="latitude" value="{{ old('latitude', $selectedAddress?->latitude) }}">
                    <input type="hidden" name="longitude" value="{{ old('longitude', $selectedAddress?->longitude) }}">
                    @if($mapsKey)
                        <div class="check-map">
                            <h3>Delivery pin <span>(optional)</span></h3>
                            @include('partials.delivery-map-picker', [
                                'mapsKey' => $mapsKey,
                                'addressSelector' => 'address_id',
                                'latitudeField' => 'latitude',
                                'longitudeField' => 'longitude',
                            ])
                        </div>
                    @endif
                </section>

                <section class="check-card">
                    <h2>Order notes</h2>
                    <div class="s3-field check-field-last">
                        <label for="notes">Note for the rider or seller <span>(optional)</span></label>
                        <textarea id="notes" name="notes" placeholder="Gate code, landmark, or a special note for delivery">{{ old('notes') }}</textarea>
                    </div>
                </section>
                <input type="hidden" name="gateway" value="cod">
            </form>
        </div>

        <aside class="check-summary">
            <div class="check-card check-order">
                <h2>Your order</h2>
                <div class="check-order-head">
                    <span>{{ $itemCount }} {{ Str::plural('item', $itemCount) }}</span>
                    <span>Subtotal</span>
                </div>
                @forelse($items as $item)
                    @php $product = $item->variant?->product; $image = $product?->primaryImage(); @endphp
                    <article class="check-line">
                        @if($image)
                            <img src="{{ asset($image->path) }}" alt="">
                        @else
                            <span class="check-line-ph" aria-hidden="true"></span>
                        @endif
                        <div>
                            <strong>{{ $product?->name ?? 'Unavailable product' }}</strong>
                            <small>× {{ $item->quantity }}</small>
                        </div>
                        <span>₱{{ number_format($item->unit_price * $item->quantity, 2) }}</span>
                    </article>
                @empty
                    <p class="check-empty">Cart is empty.</p>
                @endforelse
                <div class="s3-field check-voucher">
                    <label for="voucher_code">Shop voucher</label>
                    <input id="voucher_code" form="checkout-form" name="voucher_code" value="{{ $voucherCode }}" maxlength="20" placeholder="SHOP10" autocomplete="off">
                    @error('voucher_code')<small>{{ $message }}</small>@enderror
                </div>
                <dl class="check-totals">
                    <div><dt>Merchandise</dt><dd>₱{{ number_format($merchandise, 2) }}</dd></div>
                    <div><dt>Standard shipping</dt><dd>₱{{ number_format($shippingFee, 2) }}</dd></div>
                    <div class="check-total"><dt>Order total</dt><dd>₱{{ number_format($total, 2) }}</dd></div>
                </dl>
            </div>
            <div class="check-card check-pay">
                <p class="check-pay-method">
                    <input type="radio" name="pay_ui" checked>
                    <span>
                        <strong>Cash on Delivery</strong>
                        <small>Pay when {{ config('jeap.courier_name') }} delivers. Shipping stays ₱{{ number_format($shippingFee, 0) }}.</small>
                    </span>
                </p>
                <button class="check-place" type="submit" form="checkout-form" @disabled($items->isEmpty())>Place order</button>
            </div>
        </aside>
    </div>
</section>
@endsection
