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
        $address['postal_code'] ?? null,
    ]));
    $pickup = $order->seller?->sellerProfile?->addresses?->first();
    $origin = $pickup ? implode(', ', array_filter([$pickup->street_line, $pickup->barangay_name, $pickup->city_name, $pickup->province_name])) : ($order->seller?->sellerProfile?->business_name ?: 'Seller warehouse');
    $latitude = $address['latitude'] ?? null;
    $longitude = $address['longitude'] ?? null;
    $hasCoordinates = is_numeric($latitude) && is_numeric($longitude);
    $finalStatuses = [\App\Enums\OrderStatus::Completed, \App\Enums\OrderStatus::Cancelled, \App\Enums\OrderStatus::Returned];
    $steps = \App\Enums\OrderStatus::shopperSteps();
    $currentStep = 0;
    foreach ($steps as $index => $step) {
        if (in_array($order->status, $step['match'], true)) {
            $currentStep = $index;
        } elseif (in_array($order->status, [\App\Enums\OrderStatus::Delivered, \App\Enums\OrderStatus::Completed], true)) {
            $currentStep = count($steps) - 1;
        }
    }
    if (in_array($order->status, [\App\Enums\OrderStatus::Delivered, \App\Enums\OrderStatus::Completed], true)) {
        $currentStep = count($steps) - 1;
    }
    $rider = $order->parcel?->deliveryAssignment?->courier;
@endphp
<main class="buyer-track-page">
    <header class="buyer-track-heading">
        <div>
            <a class="buyer-track-back" href="{{ route('buyer.home') }}">← My orders</a>
            <p class="buyer-track-eyebrow">ORDER TRACKING</p>
            <h1>{{ $order->order_number }}</h1>
            <p>Placed {{ $order->placed_at?->format('M j, Y · g:i A') ?? 'Date unavailable' }} · COD</p>
        </div>
        <span class="buyer-track-status status-{{ strtolower($order->status->value) }}">{{ str($order->status->value)->replace('_', ' ')->title() }}</span>
    </header>

    @if(session('status'))<div class="buyer-track-flash">{{ session('status') }}</div>@endif
    @if($errors->any())<div class="buyer-track-error">{{ $errors->first() }}</div>@endif

    <section class="track-stepper" aria-label="Delivery progress">
        @foreach($steps as $index => $step)
            <div class="track-step {{ $index < $currentStep ? 'is-complete' : '' }} {{ $index === $currentStep ? 'is-current' : '' }}">
                <span class="track-step-dot" aria-hidden="true"></span>
                <strong>{{ $step['label'] }}</strong>
            </div>
        @endforeach
    </section>

    <div class="buyer-track-layout">
        <section class="buyer-track-main">
            <section class="buyer-track-card">
                <div class="buyer-track-card-heading">
                    <div><p class="buyer-track-eyebrow">SHIPMENT</p><h2>{{ $order->parcel?->tracking_number ?? 'Waiting for pickup' }}</h2></div>
                    @if($order->parcel)
                        <button type="button" class="track-copy" data-copy="{{ $order->parcel->tracking_number }}">Copy</button>
                    @endif
                </div>
                <div class="track-route">
                    <div><span>From</span><strong>{{ $order->seller?->sellerProfile?->business_name ?: ($order->seller?->name ?? 'Seller') }}</strong><p>{{ $origin }}</p></div>
                    <div><span>To</span><strong>{{ $address['recipient_name'] ?? auth()->user()->name }}</strong><p>{{ $destination !== '' ? $destination : 'Delivery address unavailable' }}</p></div>
                </div>
                @if($hasCoordinates)
                    <a class="buyer-track-map" href="https://www.google.com/maps/search/?api=1&amp;query={{ urlencode($latitude.','.$longitude) }}" target="_blank" rel="noopener noreferrer">Open destination in Google Maps</a>
                @endif
            </section>

            <section class="buyer-track-card">
                <div class="buyer-track-card-heading"><div><p class="buyer-track-eyebrow">UPDATES</p><h2>Tracking history</h2></div></div>
                @if($events->isEmpty())
                    <p class="buyer-track-note">Your seller is preparing this order. Updates will appear here.</p>
                @else
                    <ol class="buyer-track-timeline">
                        @foreach($events->reverse() as $event)
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
                <p class="buyer-track-eyebrow">PEOPLE ON THIS ORDER</p>
                <h2>Chat</h2>
                <form method="post" action="{{ route('chat.start') }}">@csrf<input type="hidden" name="order_id" value="{{ $order->id }}"><button class="s3-btn" type="submit">Chat about this order</button></form>
                @if($rider)
                    <div class="buyer-track-rider"><span>DELIVERY RIDER</span><strong>{{ $rider->name }}</strong>
                        @if($rider->phone)<a href="tel:{{ $rider->phone }}">{{ $rider->phone }}</a>@endif
                    </div>
                @endif
                @if($order->status === \App\Enums\OrderStatus::Delivered)
                    <form method="post" action="{{ route('buyer.orders.confirm-received', $order) }}" class="buyer-track-confirm">@csrf<button type="submit">Order received</button></form>
                @endif
            </section>

            <section class="buyer-track-card buyer-track-items">
                <p class="buyer-track-eyebrow">ORDER SUMMARY</p><h2>{{ $order->items->sum('quantity') }} items</h2>
                @foreach($order->items as $item)
                    <div><span>{{ $item->name }} × {{ $item->quantity }}</span><strong>₱{{ number_format((float) $item->subtotal, 2) }}</strong></div>
                @endforeach
                @if((float) $order->discount > 0)
                    <div><span>Voucher</span><strong>−₱{{ number_format((float) $order->discount, 2) }}</strong></div>
                @endif
                <div><span>Shipping</span><strong>₱{{ number_format((float) $order->shipping_fee, 2) }}</strong></div>
                <div class="buyer-track-total"><span>Total</span><strong>₱{{ number_format((float) $order->total, 2) }}</strong></div>
                <p class="buyer-track-seller">Sold by {{ $order->seller?->sellerProfile?->business_name ?? $order->seller?->name ?? 'JEAP seller' }}</p>
            </section>
        </aside>
    </div>
</main>
<script>
    document.querySelectorAll('[data-copy]').forEach((button) => button.addEventListener('click', async () => {
        await navigator.clipboard.writeText(button.dataset.copy);
        button.textContent = 'Copied';
        setTimeout(() => { button.textContent = 'Copy'; }, 1500);
    }));
</script>
@endsection
