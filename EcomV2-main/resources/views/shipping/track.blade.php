@extends('layouts.storefront')

@section('title', 'Track Shipment | JEAP')
@section('content')
<div class="shipping-track-page" data-figma="02_Track_Shipment 1">
    <header class="shipping-track-intro">
        <span class="shipping-eyebrow">JEAP DELIVERY</span>
        <h1>Track Shipment</h1>
        <p>Enter the tracking number from your order to view its latest recorded updates.</p>
    </header>

    <form class="shipping-lookup" action="{{ route('shipping.track') }}" method="get">
        <label for="tracking-number">Tracking number</label>
        <div class="shipping-lookup-row">
            <input id="tracking-number" type="text" name="tracking_number" value="{{ $trackingNumber }}" placeholder="e.g. JEPXXXXXXXXXX" maxlength="40" required autocomplete="off" spellcheck="false">
            <button type="submit">Track order <span aria-hidden="true">→</span></button>
        </div>
        @error('tracking_number')<p class="shipping-form-error">{{ $message }}</p>@enderror
    </form>

    @if($parcel)
        <section class="shipping-result" aria-live="polite">
            <div class="shipping-result-head">
                <div><span class="shipping-eyebrow">TRACKING NUMBER</span><h2>{{ $parcel->tracking_number }}</h2></div>
                <span class="shipping-status">{{ str($parcel->status->value)->replace('_', ' ')->title() }}</span>
            </div>
            @php
                $steps = \App\Enums\OrderStatus::shopperSteps();
                $currentStep = 0;
                foreach ($steps as $index => $step) {
                    if (in_array($parcel->status, $step['match'], true)) {
                        $currentStep = $index;
                    }
                }
                if (in_array($parcel->status, [\App\Enums\OrderStatus::Delivered, \App\Enums\OrderStatus::Completed], true)) {
                    $currentStep = count($steps) - 1;
                }
            @endphp
            <section class="track-stepper" aria-label="Delivery progress">
                @foreach($steps as $index => $step)
                    <div class="track-step {{ $index < $currentStep ? 'is-complete' : '' }} {{ $index === $currentStep ? 'is-current' : '' }}">
                        <span class="track-step-dot" aria-hidden="true"></span>
                        <strong>{{ $step['label'] }}</strong>
                    </div>
                @endforeach
            </section>
            @if($events->isEmpty())
                <p class="shipping-empty-note">No shipment events have been recorded yet. Check again after the next order update.</p>
            @else
                <ol class="shipping-timeline">
                    @foreach($events as $event)
                        <li><span class="shipping-timeline-dot" aria-hidden="true"></span><div><strong>{{ $event['label'] }}</strong><time datetime="{{ $event['at']?->toIso8601String() }}">{{ $event['at']?->format('M j, Y · g:i A') ?? 'Time unavailable' }}</time></div></li>
                    @endforeach
                </ol>
            @endif
            <p class="shipping-privacy-note">For your privacy, this public tracking page does not show your delivery address or contact details. Sign in to view full order information.</p>
        </section>
    @else
        <section class="shipping-track-help">
            <div class="shipping-help-icon" aria-hidden="true">?</div>
            <div><h2>Where can I find my tracking number?</h2><p>Open your JEAP account, choose your order, and look for the tracking number in its shipment details.</p><a href="{{ auth()->check() ? route('buyer.home') : route('login') }}">{{ auth()->check() ? 'Go to my account' : 'Sign in to JEAP' }} <span aria-hidden="true">→</span></a></div>
        </section>
    @endif
</div>
@endsection
