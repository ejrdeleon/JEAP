@extends('layouts.storefront')

@section('title', 'Track order '.$order->order_number)
@section('crumb')
    <a href="{{ route('home') }}">Home</a><span>/</span><span>Order tracking</span>
@endsection

@section('content')
@php
    $address = $order->shipping_address_snapshot ?? [];
    $destination = implode(', ', array_filter([
        $address['street_line'] ?? null,
        $address['barangay_name'] ?? null,
        $address['city_name'] ?? null,
        $address['province_name'] ?? null,
        $address['region_name'] ?? null,
        $address['country_name'] ?? null,
        $address['postal_code'] ?? null,
    ]));
    $latitude = $address['latitude'] ?? null;
    $longitude = $address['longitude'] ?? null;
    $hasCoordinates = is_numeric($latitude) && is_numeric($longitude)
        && (float) $latitude >= -90 && (float) $latitude <= 90
        && (float) $longitude >= -180 && (float) $longitude <= 180;
    $finalStatuses = [\App\Enums\OrderStatus::Completed, \App\Enums\OrderStatus::Cancelled, \App\Enums\OrderStatus::Returned];
@endphp
<main class="buyer-track-page">
    <header class="buyer-track-heading">
        <div>
            <a class="buyer-track-back" href="{{ route('buyer.home') }}">← My account</a>
            <p class="buyer-track-eyebrow">ORDER TRACKING</p>
            <h1>{{ $order->order_number }}</h1>
            <p>Placed {{ $order->placed_at?->format('M j, Y · g:i A') ?? 'Date unavailable' }}</p>
        </div>
        <span class="buyer-track-status status-{{ strtolower($order->status->value) }}">{{ str($order->status->value)->replace('_', ' ')->title() }}</span>
    </header>

    @if(session('status'))<div class="buyer-track-flash">{{ session('status') }}</div>@endif
    @if($errors->any())<div class="buyer-track-error">{{ $errors->first() }}</div>@endif

    <div class="buyer-track-layout">
        <section class="buyer-track-main">
            @if($order->status === \App\Enums\OrderStatus::DeliveryFailed)
                <div class="buyer-track-callout is-error"><strong>Delivery attempt unsuccessful</strong><p>Our logistics team is reviewing the shipment and may arrange another attempt.</p></div>
            @elseif($order->status === \App\Enums\OrderStatus::Cancelled)
                <div class="buyer-track-callout is-muted"><strong>This order was cancelled</strong><p>There are no further delivery updates for this order.</p></div>
            @elseif($order->status === \App\Enums\OrderStatus::Returned)
                <div class="buyer-track-callout is-muted"><strong>This order is being returned</strong><p>Contact JEAP support if you need help with this shipment.</p></div>
            @elseif($order->status === \App\Enums\OrderStatus::Completed)
                <div class="buyer-track-callout is-success"><strong>Order complete</strong><p>Your receipt has been confirmed. Thank you for shopping with JEAP.</p></div>
            @endif

            <section class="buyer-track-card">
                <div class="buyer-track-card-heading"><div><p class="buyer-track-eyebrow">SHIPMENT</p><h2>Delivery progress</h2></div>
                    @if($order->parcel)<span class="buyer-track-number">{{ $order->parcel->tracking_number }}</span>@endif
                </div>
                @if($order->parcel)
                    @php($progressStatuses = \App\Enums\OrderStatus::pipeline())
                    @php($currentIndex = array_search($order->status, $progressStatuses, true))
                    @if($currentIndex !== false && !in_array($order->status, $finalStatuses, true))
                        <div class="buyer-track-progress" aria-label="Shipment progress">
                            @foreach([\App\Enums\OrderStatus::ReadyForPickup, \App\Enums\OrderStatus::PickedUp, \App\Enums\OrderStatus::AtSortingCenter, \App\Enums\OrderStatus::Sorted, \App\Enums\OrderStatus::AssignedToRider, \App\Enums\OrderStatus::OutForDelivery, \App\Enums\OrderStatus::Delivered] as $step)
                                @php($stepIndex = array_search($step, $progressStatuses, true))
                                <span class="{{ $currentIndex >= $stepIndex ? 'is-complete' : '' }}">{{ str($step->value)->replace('_', ' ')->title() }}</span>
                            @endforeach
                        </div>
                    @endif
                    @if(in_array($order->status, [\App\Enums\OrderStatus::Placed, \App\Enums\OrderStatus::Confirmed, \App\Enums\OrderStatus::Preparing], true))
                        <p class="buyer-track-note">Your seller is preparing this order. Tracking will begin when it is ready for pickup.</p>
                    @endif
                @else
                    <p class="buyer-track-note">The seller is preparing your order. Shipment tracking will appear when it is ready for pickup.</p>
                @endif
            </section>

            <section class="buyer-track-card">
                <div class="buyer-track-card-heading"><div><p class="buyer-track-eyebrow">UPDATES</p><h2>Tracking history</h2></div></div>
                @if($events->isEmpty())
                    <p class="buyer-track-note">Your order updates will appear here.</p>
                @else
                    <ol class="buyer-track-timeline">
                        @foreach($events as $event)
                            <li>
                                <span class="buyer-track-dot" aria-hidden="true"></span>
                                <div><strong>{{ $event['label'] }}</strong>
                                    @if($event['notes'])<p>{{ $event['notes'] }}</p>@endif
                                    <small>{{ $event['at']?->format('M j, Y · g:i A') ?? 'Time unavailable' }}@if($event['actor']) · {{ $event['actor'] }}@endif</small>
                                </div>
                            </li>
                        @endforeach
                    </ol>
                @endif
            </section>
        </section>

        <aside class="buyer-track-side">
            <section class="buyer-track-card">
                <p class="buyer-track-eyebrow">DELIVERY DETAILS</p>
                <h2>Destination</h2>
                <p class="buyer-track-address">{{ $destination !== '' ? $destination : 'Delivery address unavailable' }}</p>
                @if($hasCoordinates)
                    <a class="buyer-track-map" href="https://www.google.com/maps/search/?api=1&amp;query={{ urlencode($latitude.','.$longitude) }}" target="_blank" rel="noopener noreferrer">Open destination in Google Maps</a>
                @endif
                @if($order->parcel?->deliveryAssignment?->courier)
                    <div class="buyer-track-rider"><span>DELIVERY RIDER</span><strong>{{ $order->parcel->deliveryAssignment->courier->name }}</strong>
                        @if($order->parcel->deliveryAssignment->courier->phone)<a href="tel:{{ $order->parcel->deliveryAssignment->courier->phone }}">{{ $order->parcel->deliveryAssignment->courier->phone }}</a>@endif
                    </div>
                @endif
                @if($order->status === \App\Enums\OrderStatus::Delivered)
                    <form method="post" action="{{ route('buyer.orders.confirm-received', $order) }}" class="buyer-track-confirm">@csrf<button type="submit">Confirm receipt</button></form>
                @endif
            </section>

            <section class="buyer-track-card buyer-track-items">
                <p class="buyer-track-eyebrow">ORDER SUMMARY</p><h2>{{ $order->items->sum('quantity') }} items</h2>
                @foreach($order->items as $item)
                    <div><span>{{ $item->name }} × {{ $item->quantity }}</span><strong>₱{{ number_format((float) $item->subtotal, 2) }}</strong></div>
                @endforeach
                <div class="buyer-track-total"><span>Total</span><strong>₱{{ number_format((float) $order->total, 2) }}</strong></div>
                <p class="buyer-track-seller">Sold by {{ $order->seller?->name ?? 'JEAP seller' }}</p>
            </section>
        </aside>
    </div>
</main>
@endsection
