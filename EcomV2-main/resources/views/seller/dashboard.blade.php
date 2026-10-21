@extends('layouts.dashboard')
@section('title', 'Seller dashboard')
@section('nav')
    <a class="active" href="{{ route('seller.dashboard') }}">Overview</a>
    <a href="{{ route('seller.catalog') }}">Products</a>
    <a href="{{ route('seller.orders') }}">Orders</a>
    <a href="{{ route('seller.promos') }}">Promotions</a>
    <a href="{{ route('seller.shipments') }}">Shipments</a>
@endsection
@section('content')
<div class="seller-page">
    <div class="seller-heading">
        <div><h1>Good to see you, {{ auth()->user()->first_name }}.</h1><p>Here’s how your store is doing today.</p></div>
        <a class="seller-primary" href="{{ route('seller.catalog') }}">＋ Add a product</a>
    </div>
    <div class="seller-stats">
        <article><span>Active products</span><strong>{{ number_format($productCount) }}</strong><a href="{{ route('seller.catalog') }}">Manage catalog →</a></article>
        <article><span>Below sellable stock</span><strong>{{ number_format($lowStockCount) }}</strong><small>Active listings with fewer than {{ \App\Commerce\InventoryPolicy::minSellableStock() }} units</small></article>
        <article><span>Open orders</span><strong>{{ number_format($openOrderCount) }}</strong><a href="{{ route('seller.orders') }}">View orders →</a></article>
    </div>
    <section class="seller-panel">
        <div class="seller-panel-head"><div><h2>Recent orders</h2><p>Your latest orders and their current status.</p></div><a href="{{ route('seller.orders') }}">All orders →</a></div>
        @if($recentOrders->isEmpty())
            <div class="seller-empty"><span>📦</span><strong>Your orders will show up here</strong><p>Once a customer buys one of your products, you can manage it from this page.</p></div>
        @else
            <div class="seller-table-wrap"><table class="seller-table"><thead><tr><th>Order</th><th>Placed</th><th>Items</th><th>Total</th><th>Commission</th><th>Est. payout</th><th>Status</th></tr></thead><tbody>
                @foreach($recentOrders as $order)
                    @php($commissionAmount = (float)($order->commission?->amount ?? 0))
                    <tr><td><strong>{{ $order->order_number }}</strong></td><td>{{ $order->placed_at?->format('M j, Y') ?? '—' }}</td><td>{{ $order->items->sum('quantity') }}</td><td>₱{{ number_format((float)$order->total, 2) }}</td><td>₱{{ number_format($commissionAmount, 2) }}</td><td>₱{{ number_format((float)$order->subtotal - $commissionAmount, 2) }}</td><td><span class="seller-badge">{{ str($order->status->value)->replace('_', ' ')->title() }}</span></td></tr>
                @endforeach
            </tbody></table></div>
        @endif
    </section>
</div>
@endsection
