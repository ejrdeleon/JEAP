@extends('layouts.dashboard')
@section('title', 'Orders')
@section('nav')
    <a href="{{ route('seller.dashboard') }}">Overview</a>
    <a href="{{ route('seller.catalog') }}">Products</a>
    <a class="active" href="{{ route('seller.orders') }}">Orders</a>
    <a href="{{ route('seller.promos') }}">Promotions</a>
    <a href="{{ route('seller.shipments') }}">Shipments</a>
@endsection
@section('content')
<div class="seller-page">
    <div class="seller-heading"><div><span class="seller-eyebrow">SELLER CENTER / ORDERS</span><h1>Orders</h1><p>Confirm new orders, prepare them, and mark parcels ready for pickup.</p></div></div>
    @if(session('status'))<div class="seller-flash">{{ session('status') }}</div>@endif
    @if($errors->any())<div class="seller-errors">{{ $errors->first() }}</div>@endif
    <section class="seller-panel">
        <div class="seller-panel-head"><div><h2>All orders</h2><p>Commission and estimated seller payout are shown for each order.</p></div></div>
        @if($orders->isEmpty())
            <div class="seller-empty"><span>📦</span><strong>No orders to show</strong><p>New customer orders will appear here.</p></div>
        @else
            <div class="seller-table-wrap"><table class="seller-table"><thead><tr><th>Order</th><th>Customer</th><th>Items</th><th>Order total</th><th>Commission (10%)</th><th>Estimated payout</th><th>Status / next step</th></tr></thead><tbody>
                @foreach($orders as $order)
                    @php
                        $next = match($order->status) {
                            \App\Enums\OrderStatus::Placed => ['CONFIRMED' => 'Confirm', 'CANCELLED' => 'Cancel'],
                            \App\Enums\OrderStatus::Confirmed => ['PREPARING' => 'Start preparing', 'CANCELLED' => 'Cancel'],
                            \App\Enums\OrderStatus::Preparing => ['READY_FOR_PICKUP' => 'Ready for pickup'],
                            default => [],
                        };
                        $commission = (float)($order->commission?->amount ?? 0);
                    @endphp
                    <tr>
                        <td><strong>{{ $order->order_number }}</strong><small class="seller-subline">{{ $order->placed_at?->format('M j, Y · g:i A') ?? '—' }}</small></td>
                        <td>{{ $order->buyer?->name ?? 'Customer' }}</td>
                        <td><strong>{{ $order->items->sum('quantity') }}</strong><small class="seller-subline">{{ $order->items->pluck('name')->join(', ') }}</small></td>
                        <td>₱{{ number_format((float)$order->total, 2) }}</td>
                        <td>₱{{ number_format($commission, 2) }}</td>
                        <td><strong>₱{{ number_format((float)$order->total - $commission, 2) }}</strong></td>
                        <td><span class="seller-badge {{ in_array($order->status->value, ['COMPLETED', 'DELIVERED']) ? 'is-active' : '' }}">{{ str($order->status->value)->replace('_', ' ')->title() }}</span>
                            @if($next)<div class="seller-order-actions">@foreach($next as $status => $label)<form method="post" action="{{ route('seller.orders.status', $order) }}">@csrf @method('PATCH')<input type="hidden" name="status" value="{{ $status }}"><button class="{{ $status === 'CANCELLED' ? 'is-danger' : '' }}" type="submit">{{ $label }}</button></form>@endforeach</div>@endif
                        </td>
                    </tr>
                @endforeach
            </tbody></table></div>
            <div class="seller-pagination">{{ $orders->links() }}</div>
        @endif
    </section>
</div>
@endsection
