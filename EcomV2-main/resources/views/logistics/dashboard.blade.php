@extends('layouts.dashboard')

@section('title', 'Shipment Operations')
@section('nav')
    @include('partials.logistics-nav')
@endsection

@section('content')
<div class="shipment-page">
    <header class="shipment-heading">
        <div>
            <h1>Shipments</h1>
            <p>Grouped by destination. Assign pickups, receive parcels at the hub, then send them out for delivery. Logistics keeps 20% of merchandise plus the ₱{{ number_format(config('jeap.shipping_fee'), 0) }} shipping fee.</p>
        </div>
        <form method="get" class="shipment-area-filter">
            <label for="area">Destination</label>
            <select id="area" name="area" onchange="this.form.submit()">
                <option value="">All areas</option>
                @foreach($areas ?? [] as $areaName)
                    <option value="{{ $areaName }}" @selected(($selectedArea ?? '') === $areaName)>{{ $areaName }}</option>
                @endforeach
            </select>
        </form>
    </header>

    @if(session('status'))<div class="shipment-notice is-success">{{ session('status') }}</div>@endif
    @if($errors->any())<div class="shipment-notice is-error">{{ $errors->first() }}</div>@endif

    <section class="shipment-panel">
        <div class="shipment-panel-heading">
            <div><h2>Active fulfillment</h2><p>Riders shown here are approved and currently available.</p></div>
            <span>{{ $orders->total() }} shipments</span>
        </div>

        @forelse($groupedOrders ?? $orders->groupBy(fn () => 'Shipments') as $areaName => $areaOrders)
            <h3 class="shipment-area-title">{{ $areaName }}</h3>
            @foreach($areaOrders as $order)
            @php
                $parcel = $order->parcel;
                $pickup = $parcel?->pickupAssignment;
                $delivery = $parcel?->deliveryAssignment;
                $riderOptions = $couriers->concat(collect([$pickup?->courier, $delivery?->courier])->filter())->unique('id')->sortBy('first_name');
                $status = $order->status;
                $destination = trim(implode(', ', array_filter([
                    $order->shipping_address_snapshot['barangay_name'] ?? null,
                    $order->shipping_address_snapshot['city_name'] ?? null,
                    $order->shipping_address_snapshot['region_name'] ?? null,
                ])));
                $cut = (float) ($order->commission?->amount ?? 0);
            @endphp
            <article class="shipment-row">
                <div class="shipment-order-summary">
                    <span class="shipment-status">{{ str($status->value)->replace('_', ' ')->title() }}</span>
                    <h3>{{ $order->order_number }}</h3>
                    <p>{{ $parcel->tracking_number }} <span>·</span> {{ $order->seller?->name ?? 'Seller' }} to {{ $order->buyer?->name ?? 'Buyer' }}</p>
                    @if($destination)<p>{{ $destination }}</p>@endif
                    <small>Placed {{ $order->placed_at?->format('M j, Y · g:i A') ?? '—' }} · Logistics cut ₱{{ number_format($cut, 2) }}</small>
                </div>

                <div class="shipment-assignment">
                    <strong>Pickup</strong>
                    @if($pickup?->courier)
                        <span>{{ $pickup->courier->name }}</span><small>{{ str($pickup->status)->replace('_', ' ')->title() }}</small>
                    @else
                        <span>Rider not assigned</span>
                    @endif
                    @if($status === \App\Enums\OrderStatus::ReadyForPickup)
                        <form method="post" action="{{ route('logistics.shipments.assign-pickup', $parcel) }}" class="shipment-action-form">
                            @csrf
                            <select name="courier_id" aria-label="Choose pickup rider" required>
                                <option value="">Choose available rider</option>
                                @foreach($riderOptions as $courier)<option value="{{ $courier->id }}">{{ $courier->name }}</option>@endforeach
                            </select>
                            <button type="submit">{{ $pickup?->courier_id ? 'Reassign' : 'Assign pickup' }}</button>
                        </form>
                    @endif
                </div>

                <div class="shipment-assignment">
                    <strong>Delivery</strong>
                    @if($delivery?->courier)
                        <span>{{ $delivery->courier->name }}</span><small>{{ str($delivery->status)->replace('_', ' ')->title() }}</small>
                    @else
                        <span>Rider not assigned</span>
                    @endif
                    @if(in_array($status, [\App\Enums\OrderStatus::Sorted, \App\Enums\OrderStatus::DeliveryFailed], true))
                        <form method="post" action="{{ route('logistics.shipments.assign-delivery', $parcel) }}" class="shipment-action-form">
                            @csrf
                            <select name="courier_id" aria-label="Choose delivery rider" required>
                                <option value="">Choose available rider</option>
                                @foreach($riderOptions as $courier)<option value="{{ $courier->id }}">{{ $courier->name }}</option>@endforeach
                            </select>
                            <button type="submit">{{ $status === \App\Enums\OrderStatus::DeliveryFailed ? 'Reassign delivery' : 'Assign delivery' }}</button>
                        </form>
                    @endif
                </div>

                <div class="shipment-next-step">
                    @if($status === \App\Enums\OrderStatus::PickedUp)
                        <form method="post" action="{{ route('logistics.shipments.progress', $parcel) }}">@csrf<input type="hidden" name="status" value="AT_SORTING_CENTER"><button type="submit">Receive at hub</button></form>
                    @elseif($status === \App\Enums\OrderStatus::AtSortingCenter)
                        <form method="post" action="{{ route('logistics.shipments.progress', $parcel) }}">@csrf<input type="hidden" name="status" value="SORTED"><button type="submit">Mark sorted</button></form>
                    @elseif($status === \App\Enums\OrderStatus::OutForDelivery)
                        <span class="shipment-muted">With rider for delivery</span>
                    @elseif($status === \App\Enums\OrderStatus::Delivered || $status === \App\Enums\OrderStatus::Completed)
                        <span class="shipment-muted">Delivery complete</span>
                    @elseif($status === \App\Enums\OrderStatus::DeliveryFailed)
                        <span class="shipment-muted is-error">Delivery failed · reassign to retry</span>
                    @endif
                </div>
            </article>
            @endforeach
        @empty
            <div class="shipment-empty"><strong>No shipments need attention</strong><p>Orders appear here once the seller marks them ready for pickup.</p></div>
        @endforelse

        @if($orders->hasPages())<div class="shipment-pagination">{{ $orders->links() }}</div>@endif
    </section>
</div>
@endsection
