@extends('layouts.storefront')

@section('title', 'Shipping | JEAP')
@section('content')
<div class="shipping-home" data-figma="01_Home 1">
    <section class="shipping-hero">
        <div class="shipping-hero-copy">
            <span class="shipping-eyebrow">JEAP DELIVERY</span>
            <h1>Your order, on its way.</h1>
            <p>Follow your JEAP purchase from seller preparation through the delivery updates recorded for your shipment.</p>
            <a class="shipping-primary-link" href="{{ route('shipping.track') }}">Track a shipment <span aria-hidden="true">→</span></a>
        </div>
        <div class="shipping-route-art" aria-hidden="true">
            <span class="shipping-route-line"></span>
            <span class="shipping-route-point is-start"><i>1</i></span>
            <span class="shipping-route-point is-middle"><i>2</i></span>
            <span class="shipping-route-point is-end"><i>3</i></span>
            <div class="shipping-route-label label-start"><strong>Seller</strong><small>Preparing your order</small></div>
            <div class="shipping-route-label label-middle"><strong>On the way</strong><small>Shipment updates</small></div>
            <div class="shipping-route-label label-end"><strong>Your door</strong><small>Delivery complete</small></div>
        </div>
    </section>

    <section class="shipping-how">
        <div class="shipping-section-heading">
            <span class="shipping-eyebrow">SIMPLE FROM START TO ARRIVAL</span>
            <h2>Know where your order stands</h2>
            <p>Tracking details appear as your order moves through the steps recorded by JEAP sellers and delivery teams.</p>
        </div>
        <div class="shipping-steps">
            <article class="shipping-step"><span>01</span><h3>Seller prepares</h3><p>Your seller confirms the order and marks it ready for pickup.</p></article>
            <article class="shipping-step"><span>02</span><h3>Shipment moves</h3><p>Pickup and logistics updates are added to your tracking timeline.</p></article>
            <article class="shipping-step"><span>03</span><h3>Rider delivers</h3><p>See the latest recorded delivery status and confirm receipt from your account.</p></article>
        </div>
    </section>

    <section class="shipping-track-cta">
        <div><span class="shipping-eyebrow">HAVE A TRACKING NUMBER?</span><h2>Get the latest shipment update.</h2></div>
        <a class="shipping-secondary-link" href="{{ route('shipping.track') }}">Go to tracking <span aria-hidden="true">→</span></a>
    </section>
</div>
@endsection
