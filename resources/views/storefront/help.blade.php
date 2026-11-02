@extends('layouts.storefront')
@section('title', 'Help')
@section('crumb')
    <span>help</span>
@endsection
@section('content')
<section class="s3-main help-page" data-figma="14_Help_Support 1">
    <h1>Help &amp; Support</h1>
    <p class="lede">JEAP is Cash on Delivery only. Shipping is a flat ₱{{ number_format($shippingFee, 0) }} per seller order.</p>

    <div class="help-grid">
        <article>
            <h2>Track an order</h2>
            <p>Open <a href="{{ route('buyer.home') }}">My orders</a> or enter the tracking number on <a href="{{ route('shipping.track') }}">Track shipment</a>. Public tracking does not show your address.</p>
        </article>
        <article>
            <h2>Seller packing</h2>
            <p>Sellers confirm the order, start preparing, then mark it ready for pickup. That is the packing step. {{ config('jeap.courier_name') }} riders collect from the shop after the hub assigns pickup.</p>
        </article>
        <article>
            <h2>Parcel scan</h2>
            <p>Riders accept an assignment and confirm pickup from the rider dashboard. The hub then receives and sorts the parcel before last-mile delivery. Proof of delivery is a photo taken at the door.</p>
        </article>
        <article>
            <h2>Returns and complaints</h2>
            <p>After an order is delivered, request a return or file a complaint from the order page. Ratings are available once you tap Order received.</p>
        </article>
    </div>

    @if($policies->isNotEmpty())
        <h2>Policies</h2>
        <ul class="help-policies">
            @foreach($policies as $policy)
                <li><a href="{{ route('policies.show', $policy->key) }}">{{ $policy->title }}</a></li>
            @endforeach
        </ul>
    @endif

    <p><a class="s3-btn" href="{{ route('contact') }}">Contact JEAP</a></p>
</section>
@endsection
