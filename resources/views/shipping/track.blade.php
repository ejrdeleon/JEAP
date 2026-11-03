@extends('layouts.storefront')

@section('title', 'Track order')
@section('crumb')
    <span>Track order</span>
@endsection

@section('content')
<div class="shipping-track-page {{ auth()->check() ? 'is-live' : '' }}" data-shipping-track data-poll="{{ $liveUrl }}" data-courier="{{ config('jeap.courier_name') }}">
    <header class="shipping-track-intro">
        <span class="shipping-eyebrow">{{ config('jeap.courier_name') }}</span>
        <h1>Track your orders</h1>
        <p>
            @auth
                Live updates for your current JEAP orders appear below as sellers and {{ config('jeap.courier_name') }} record new status.
            @else
                Look up a {{ config('jeap.courier_name') }} tracking number, or log in to follow your current orders live.
            @endauth
        </p>
    </header>

    @auth
        <section class="shipping-live" data-shipping-live aria-live="polite">
            <div class="shipping-live-head">
                <div>
                    <span class="shipping-eyebrow">CURRENT ORDERS</span>
                    <h2>In progress</h2>
                </div>
                <p class="shipping-live-pulse"><span aria-hidden="true"></span> Live</p>
            </div>
            <div class="shipping-live-list" data-shipping-orders>
                @forelse($currentOrders as $card)
                    @include('shipping.partials.order-card', ['card' => $card])
                @empty
                    <p class="shipping-live-empty" data-shipping-empty>No orders in progress. New {{ config('jeap.courier_name') }} updates will appear here after you check out with Cash on Delivery.</p>
                @endforelse
            </div>
        </section>
    @else
        <section class="shipping-track-help">
            <div class="shipping-help-icon" aria-hidden="true">●</div>
            <div>
                <h2>See your current orders live</h2>
                <p>Log in to follow every JEAP order from seller prep through {{ config('jeap.courier_name') }} delivery.</p>
                <a href="{{ route('login') }}">Log in <span aria-hidden="true">→</span></a>
            </div>
        </section>
    @endauth

    <form class="shipping-lookup" action="{{ route('shipping.track') }}" method="get">
        <label for="tracking-number">JEAP Dash tracking number</label>
        <div class="shipping-lookup-row">
            <input id="tracking-number" type="text" name="tracking_number" value="{{ $trackingNumber }}" placeholder="e.g. JD-20261030-A1B2C" maxlength="40" required autocomplete="off" spellcheck="false">
            <button type="submit">Track <span aria-hidden="true">→</span></button>
        </div>
        @error('tracking_number')<p class="shipping-form-error">{{ $message }}</p>@enderror
        @if(!empty($notFound))<p class="shipping-form-error" role="alert">We could not find that tracking number. Check the number on your order and try again.</p>@endif
    </form>

    @if($lookupCard)
        <section class="shipping-result" data-shipping-lookup aria-live="polite">
            <div class="shipping-result-head">
                <div>
                    <span class="shipping-eyebrow">{{ config('jeap.courier_name') }} tracking number</span>
                    <h2 data-lookup-number>{{ $lookupCard['tracking_number'] }}</h2>
                </div>
                <span class="shipping-status" data-lookup-status>{{ $lookupCard['status'] }}</span>
            </div>
            <section class="track-stepper" aria-label="Delivery progress">
                <div class="track-stepper-row" data-lookup-steps>
                    @foreach($lookupCard['steps'] as $step)
                        <div class="track-step {{ $step['state'] === 'complete' ? 'is-complete' : '' }} {{ $step['state'] === 'current' ? 'is-current' : '' }}">
                            <span class="track-step-mark" aria-hidden="true">{{ $step['mark'] }}</span>
                            <strong>{{ $step['label'] }}</strong>
                        </div>
                    @endforeach
                </div>
            </section>
            <p class="shipping-empty-note" data-lookup-empty @if(count($lookupCard['events'])) hidden @endif>No shipment events have been recorded yet. Check again after the next order update.</p>
            <ol class="shipping-timeline" data-lookup-events @if(!count($lookupCard['events'])) hidden @endif>
                @foreach($lookupCard['events'] as $event)
                    <li>
                        <span class="shipping-timeline-dot" aria-hidden="true"></span>
                        <div>
                            <strong>{{ $event['label'] }}</strong>
                            <time datetime="{{ $event['iso'] ?? '' }}">{{ $event['at'] }}</time>
                        </div>
                    </li>
                @endforeach
            </ol>
            <p class="shipping-privacy-note">For your privacy, this public tracking page does not show your delivery address or contact details. Log in to view full order information.</p>
        </section>
    @endif
</div>
@endsection
