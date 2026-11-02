@extends('layouts.storefront')
@section('title', $title)
@section('content')
<div class="shipping-home">
    <section class="shipping-hero">
        <div class="shipping-hero-copy">
            <span class="shipping-eyebrow">{{ config('jeap.courier_name') }}</span>
            <h1>{{ $heading }}</h1>
            <p>{{ config('jeap.courier_name') }} delivers JEAP marketplace orders. Shoppers pay Cash on Delivery. Shipping is a flat ₱{{ number_format(\App\Commerce\InventoryPolicy::shippingFee(), 0) }} per seller order — it is not mixed into merchandise and it is not a percentage of the cart.</p>
            <a class="shipping-primary-link" href="{{ route('shipping.track') }}">Track a shipment <span aria-hidden="true">→</span></a>
        </div>
    </section>
    <section class="shipping-how">
        <div class="shipping-section-heading">
            <span class="shipping-eyebrow">WHAT YOU PAY</span>
            <h2>Simple, listed prices</h2>
        </div>
        <div class="shipping-steps">
            <article class="shipping-step"><span>01</span><h3>Merchandise</h3><p>The product prices in your cart, minus any shop voucher.</p></article>
            <article class="shipping-step"><span>02</span><h3>Shipping ₱{{ number_format(\App\Commerce\InventoryPolicy::shippingFee(), 0) }}</h3><p>Charged once per seller order and collected with Cash on Delivery.</p></article>
            <article class="shipping-step"><span>03</span><h3>No card checkout</h3><p>Pay the rider when the parcel arrives. Card brands on product pages are not payment methods.</p></article>
        </div>
    </section>
</div>
@endsection
