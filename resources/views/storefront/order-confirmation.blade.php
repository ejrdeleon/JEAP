@extends('layouts.storefront')

@section('title', 'Order confirmation')
@section('crumb')
    <a href="{{ route('products.index') }}">shop</a>
    <span>/</span>
    <span>order confirmation</span>
@endsection

@section('content')
@php
    $first = $orders->first();
    $address = $first->shipping_address_snapshot ?? [];
    $destination = implode(', ', array_filter([
        $address['street_line'] ?? null,
        $address['barangay_name'] ?? null,
        $address['city_name'] ?? null,
        $address['province_name'] ?? null,
        $address['postal_code'] ?? null,
    ]));
@endphp
<main class="order-confirm">
    <header class="order-confirm-heading">
        <p class="buyer-home-eyebrow">ORDER CONFIRMATION</p>
        <h1>Your COD order is placed</h1>
        <p>Stock was taken from the listing when this order was confirmed. Keep the order record below for your records.</p>
    </header>

    @if (session('toast'))
        <div class="buyer-home-flash" role="status">{{ session('toast') }}</div>
    @endif

    @foreach ($orders as $order)
        <article class="order-confirm-card">
            <div class="order-confirm-card-head">
                <div>
                    <p class="buyer-home-eyebrow">ORDER RECORD</p>
                    <h2>{{ $order->order_number }}</h2>
                    <p>Placed {{ $order->placed_at?->format('M j, Y · g:i A') ?? 'just now' }} · Cash on Delivery · {{ str($order->status->value)->replace('_', ' ')->title() }}</p>
                </div>
                <strong>₱{{ number_format((float) $order->total, 2) }}</strong>
            </div>

            <section class="order-confirm-block">
                <h3>Stock before and after this order</h3>
                @include('partials.order-stock-record', ['order' => $order])
            </section>

            <dl class="order-confirm-meta">
                <div><dt>Seller</dt><dd>{{ $order->seller?->sellerProfile?->business_name ?? $order->seller?->name ?? 'JEAP seller' }}</dd></div>
                <div><dt>Payment</dt><dd>Cash on Delivery</dd></div>
                <div><dt>Merchandise</dt><dd>₱{{ number_format((float) $order->subtotal, 2) }}</dd></div>
                @if ((float) $order->discount > 0)
                    <div><dt>Voucher</dt><dd>−₱{{ number_format((float) $order->discount, 2) }}</dd></div>
                @endif
                <div><dt>Shipping</dt><dd>₱{{ number_format((float) $order->shipping_fee, 2) }}</dd></div>
                <div><dt>Deliver to</dt><dd>{{ $destination !== '' ? $destination : 'Saved delivery address' }}</dd></div>
            </dl>

            <div class="order-confirm-actions">
                <a class="s3-btn" href="{{ route('buyer.orders.track', $order) }}">View order record</a>
            </div>
        </article>
    @endforeach

    <p class="order-confirm-next">
        <a href="{{ route('buyer.home') }}">Go to my orders</a>
        <a href="{{ route('products.index') }}">Continue shopping</a>
    </p>
</main>
@endsection
