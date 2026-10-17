@extends('layouts.dashboard')

@section('title', 'Shipments')
@section('nav')
    <a href="{{ route('seller.dashboard') }}">Overview</a>
    <a href="{{ route('seller.catalog') }}">Products</a>
    <a href="{{ route('seller.orders') }}">Orders</a>
    <a href="{{ route('seller.promos') }}">Promotions</a>
    <a class="active" href="{{ route('seller.shipments') }}">Shipments</a>
@endsection

@section('content')
<div class="seller-page">
    <div class="seller-heading"><div><span class="seller-eyebrow">SELLER CENTER / FULFILLMENT</span><h1>Shipments</h1><p>Follow pickup and delivery progress for orders ready to leave your store.</p></div></div>
    <section class="seller-panel">
        <div class="seller-panel-head"><div><h2>Your parcels</h2><p>Tracking updates are recorded as logistics and riders handle each parcel.</p></div></div>
        @if($orders->isEmpty())
            <div class="seller-empty"><strong>No shipments yet</strong><p>Mark an order ready for pickup to start its shipment.</p><a href="{{ route('seller.orders') }}">Go to orders</a></div>
        @else
            <div class="seller-table-wrap"><table class="seller-table"><thead><tr><th>Order / Tracking</th><th>Order status</th><th>Pickup rider</th><th>Delivery rider</th><th>Progress</th></tr></thead><tbody>
                @foreach($orders as $order)
                    @php($parcel = $order->parcel)
                    <tr>
                        <td><strong>{{ $order->order_number }}</strong><small class="seller-subline">{{ $parcel->tracking_number }}</small></td>
                        <td><span class="seller-badge {{ in_array($order->status->value, ['DELIVERED', 'COMPLETED']) ? 'is-active' : '' }}">{{ str($order->status->value)->replace('_', ' ')->title() }}</span></td>
                        <td>{{ $parcel->pickupAssignment?->courier?->name ?? 'Awaiting assignment' }}<small class="seller-subline">{{ $parcel->pickupAssignment ? str($parcel->pickupAssignment->status)->replace('_', ' ')->title() : 'Pickup pending' }}</small></td>
                        <td>{{ $parcel->deliveryAssignment?->courier?->name ?? 'Not assigned' }}<small class="seller-subline">{{ $parcel->deliveryAssignment ? str($parcel->deliveryAssignment->status)->replace('_', ' ')->title() : 'At seller / hub' }}</small></td>
                        <td>{{ $parcel->updated_at?->format('M j, Y · g:i A') ?? '—' }}</td>
                    </tr>
                @endforeach
            </tbody></table></div>
            <div class="seller-pagination">{{ $orders->links() }}</div>
        @endif
    </section>
</div>
@endsection
