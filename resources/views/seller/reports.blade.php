@extends('layouts.dashboard')
@section('title', 'Sales and commission')
@section('nav')
    @include('partials.seller-nav', ['active' => 'reports'])
@endsection
@section('content')
@php
    $maxSales = max(1, $monthlySales->max('sales'));
@endphp
<div class="seller-page">
    <div class="seller-heading">
        <div>
            <h1>Sales and commission</h1>
            <p>Merchandise totals for your store. Logistics keeps {{ number_format($commissionRate, 0) }}% of the subtotal. Shipping is not part of your payout.</p>
        </div>
    </div>
    <form class="seller-report-filters" method="get" action="{{ route('seller.reports') }}">
        <label class="seller-field">From
            <input type="date" name="from" value="{{ $from->toDateString() }}" required>
        </label>
        <label class="seller-field">To
            <input type="date" name="to" value="{{ $to->toDateString() }}" required>
        </label>
        <button class="seller-primary" type="submit">Apply dates</button>
    </form>
    @if($errors->any())<div class="seller-errors">{{ $errors->first() }}</div>@endif
    <div class="seller-stats seller-stats-four">
        <article><span>Orders</span><strong>{{ number_format($orderCount) }}</strong><small>{{ $from->format('M j') }} – {{ $to->format('M j, Y') }}</small></article>
        <article><span>Merchandise sales</span><strong>₱{{ number_format($merchandiseSales, 2) }}</strong><small>Subtotal only, shipping excluded</small></article>
        <article><span>Logistics ({{ number_format($commissionRate, 0) }}%)</span><strong>₱{{ number_format($logisticsCommission, 2) }}</strong><small>Voided commission is excluded</small></article>
        <article><span>Estimated payout</span><strong>₱{{ number_format($estimatedPayout, 2) }}</strong><small>Sales minus logistics cut</small></article>
    </div>
    <div class="seller-report-grid">
        <section class="seller-panel">
            <div class="seller-panel-head"><div><h2>Monthly sales</h2><p>Six most recent calendar months, merchandise subtotal</p></div></div>
            <div class="seller-report-bars">
                @foreach ($monthlySales as $month)
                    <div class="admin-bar-row"><span>{{ $month['label'] }}</span><div class="admin-bar-track"><i style="width: {{ min(100, $month['sales'] / $maxSales * 100) }}%"></i></div><strong>₱{{ number_format($month['sales'], 2) }}</strong></div>
                @endforeach
            </div>
        </section>
        <section class="seller-panel">
            <div class="seller-panel-head"><div><h2>Top products</h2><p>Ranked by units sold in the selected dates</p></div></div>
            <div class="seller-table-wrap">
                <table class="seller-table">
                    <thead><tr><th>Product</th><th>Units</th><th>Revenue</th></tr></thead>
                    <tbody>
                        @forelse ($topProducts as $product)
                            <tr><td>{{ $product->name }}</td><td>{{ number_format($product->units_sold) }}</td><td>₱{{ number_format($product->revenue, 2) }}</td></tr>
                        @empty
                            <tr><td colspan="3"><div class="seller-empty"><strong>No product sales in this range</strong><p>Completed sales will rank here once customers buy from your catalog.</p></div></td></tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </section>
    </div>
    <section class="seller-panel">
        <div class="seller-panel-head"><div><h2>Orders in range</h2><p>Cancelled and returned orders are left out of these totals.</p></div></div>
        @if($orders->isEmpty())
            <div class="seller-empty"><span>📊</span><strong>No orders in this date range</strong><p>Try a wider window, or wait for a customer to place an order.</p></div>
        @else
            <div class="seller-table-wrap">
                <table class="seller-table">
                    <thead><tr><th>Order</th><th>Placed</th><th>Status</th><th>Subtotal</th><th>Logistics</th><th>Payout</th><th>Payout status</th></tr></thead>
                    <tbody>
                        @foreach ($orders as $order)
                            @php
                                $commissionAmount = (float) ($order->commission?->status === 'void' ? 0 : ($order->commission?->amount ?? 0));
                            @endphp
                            <tr>
                                <td><strong>{{ $order->order_number }}</strong></td>
                                <td>{{ $order->placed_at?->format('M j, Y') ?? '—' }}</td>
                                <td><span class="seller-badge">{{ str($order->status->value)->replace('_', ' ')->title() }}</span></td>
                                <td>₱{{ number_format((float) $order->subtotal, 2) }}</td>
                                <td>₱{{ number_format($commissionAmount, 2) }}</td>
                                <td><strong>₱{{ number_format((float) $order->subtotal - $commissionAmount, 2) }}</strong></td>
                                <td>{{ $order->commission?->status === 'paid' ? 'Paid' : ($order->commission?->status === 'void' ? 'Void' : 'Pending remittance') }}</td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
            <div class="seller-pagination">{{ $orders->links() }}</div>
        @endif
    </section>
</div>
@endsection
