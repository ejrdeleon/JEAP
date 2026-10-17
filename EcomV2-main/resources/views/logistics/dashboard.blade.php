@extends('layouts.dashboard')

@section('title', 'Shipment Operations')
@section('nav')
    <a class="active" href="{{ route('logistics.shipments') }}">Shipments</a>
    <a href="{{ route('logistics.couriers') }}">Courier approvals</a>
@endsection

@section('content')
<div class="shipment-page">
    <header class="shipment-heading">
        <div>
            <span class="shipment-eyebrow">JEAP OPERATIONS</span>
            <h1>Shipments</h1>
            <p>Assign pickups, record sorting-center handoffs, and send sorted parcels for delivery.</p>
        </div>
    </header>

    @if(session('status'))<div class="shipment-notice is-success">{{ session('status') }}</div>@endif
    @if($errors->any())<div class="shipment-notice is-error">{{ $errors->first() }}</div>@endif

    <section class="shipment-panel">
        <div class="shipment-panel-heading">
            <div><h2>Active fulfillment</h2><p>Riders shown here are approved and currently available.</p></div>
            <span>{{ $orders->total() }} shipments</span>
        </div>

        @forelse($orders as $order)
            @php
                $parcel = $order->parcel;
                $pickup = $parcel?->pickupAssignment;
                $delivery = $parcel?->deliveryAssignment;
                $riderOptions = $couriers->concat(collect([$pickup?->courier, $delivery?->courier])->filter())->unique('id')->sortBy('first_name');
                $status = $order->status;
            @endphp
            <article class="shipment-row">
                <div class="shipment-order-summary">
                    <span class="shipment-status">{{ str($status->value)->replace('_', ' ')->title() }}</span>
                    <h3>{{ $order->order_number }}</h3>
                    <p>{{ $parcel->tracking_number }} <span>·</span> {{ $order->seller?->name ?? 'Seller' }} to {{ $order->buyer?->name ?? 'Buyer' }}</p>
                    <small>Placed {{ $order->placed_at?->format('M j, Y · g:i A') ?? '—' }}</small>
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
        @empty
            <div class="shipment-empty"><strong>No shipments need attention</strong><p>Orders appear here once the seller marks them ready for pickup.</p></div>
        @endforelse

        @if($orders->hasPages())<div class="shipment-pagination">{{ $orders->links() }}</div>@endif
    </section>
</div>
@endsection
