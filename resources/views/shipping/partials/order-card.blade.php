@php
    $card = $card ?? [];
    $steps = $card['steps'] ?? [];
    $events = $card['events'] ?? [];
@endphp
<article class="shipping-order" data-order-id="{{ $card['id'] ?? '' }}">
    <div class="shipping-result-head">
        <div>
            <span class="shipping-eyebrow">JEAP order number</span>
            <h2>{{ $card['order_number'] ?? '' }}</h2>
            <p class="shipping-order-meta">
                {{ $card['shop'] ?? 'JEAP seller' }}
                @if(!empty($card['tracking_number']))
                    <span aria-hidden="true">·</span>
                    {{ config('jeap.courier_name') }} {{ $card['tracking_number'] }}
                @else
                    <span aria-hidden="true">·</span>
                    Waiting for {{ config('jeap.courier_name') }} pickup
                @endif
            </p>
        </div>
        <span class="shipping-status" data-order-status>{{ $card['status'] ?? '' }}</span>
    </div>
    <section class="track-stepper" aria-label="Delivery progress">
        <div class="track-stepper-row" data-order-steps>
            @foreach($steps as $step)
                <div class="track-step {{ $step['state'] === 'complete' ? 'is-complete' : '' }} {{ $step['state'] === 'current' ? 'is-current' : '' }}">
                    <span class="track-step-mark" aria-hidden="true">{{ $step['mark'] }}</span>
                    <strong>{{ $step['label'] }}</strong>
                </div>
            @endforeach
        </div>
    </section>
    <ol class="shipping-timeline" data-order-events>
        @forelse($events as $event)
            <li>
                <span class="shipping-timeline-dot" aria-hidden="true"></span>
                <div>
                    <strong>{{ $event['label'] }}</strong>
                    <time datetime="{{ $event['iso'] ?? '' }}">{{ $event['at'] }}</time>
                </div>
            </li>
        @empty
            <li class="shipping-empty-event"><span class="shipping-timeline-dot" aria-hidden="true"></span><div><strong>No shipment events yet</strong><span>JEAP Dash updates will appear here.</span></div></li>
        @endforelse
    </ol>
    @if(!empty($card['href']))
        <a class="shipping-order-link" href="{{ $card['href'] }}">Open order <span aria-hidden="true">→</span></a>
    @endif
</article>
