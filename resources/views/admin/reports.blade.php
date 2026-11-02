@extends('layouts.dashboard')
@section('title', 'Reports')
@section('nav')
    @include('partials.admin-nav', ['active' => 'reports'])
@endsection
@section('content')
    <section class="admin-page">
        <header class="admin-heading"><div><h1>Reports</h1><p>Order, sales, and the {{ number_format($commissionRate, 0) }}% logistics cut on merchandise.</p></div></header>
        @if (session('status')) <p class="admin-notice">{{ session('status') }}</p> @endif
        @if ($errors->any()) <p class="admin-error">{{ $errors->first() }}</p> @endif
        <section class="admin-panel">
            <div class="admin-panel-heading">
                <div>
                    <h2>Commission settings</h2>
                    <p>Logistics keeps this percent of the merchandise subtotal. Shipping (₱{{ number_format(\App\Commerce\InventoryPolicy::shippingFee(), 0) }}) is not included. Default is 20%.</p>
                </div>
            </div>
            <form method="post" action="{{ route('admin.commission-rate.update') }}" class="admin-inline-form">
                @csrf @method('PUT')
                <label class="admin-field"><span>Rate (%)</span>
                    <input type="number" name="commission_rate" min="1" max="50" step="0.01" required value="{{ old('commission_rate', number_format($commissionRate, 2, '.', '')) }}">
                </label>
                <button class="admin-button">Save rate</button>
            </form>
        </section>
        <div class="admin-stats admin-stats-three">
            <article><span>Total orders</span><strong>{{ number_format($totalOrders) }}</strong></article>
            <article><span>Gross sales</span><strong>₱{{ number_format($grossSales, 2) }}</strong></article>
            <article><span>Active marketplace users</span><strong>{{ number_format($activeUsers) }}</strong></article>
            <article><span>Logistics commission</span><strong>₱{{ number_format($logisticsCommission, 2) }}</strong><small>{{ number_format($pendingCommission, 2) }} pending</small></article>
        </div>
        <div class="admin-report-grid">
            <section class="admin-panel"><h2>Monthly sales</h2><p class="admin-subtitle">Six most recent calendar months</p>
                @php($maxSales = max(1, $monthlySales->max('sales')))
                @foreach ($monthlySales as $month)
                    <div class="admin-bar-row"><span>{{ $month['label'] }}</span><div class="admin-bar-track"><i style="width: {{ min(100, $month['sales'] / $maxSales * 100) }}%"></i></div><strong>₱{{ number_format($month['sales'], 2) }}</strong></div>
                @endforeach
            </section>
            <section class="admin-panel"><h2>Account statuses</h2><p class="admin-subtitle">Current registered accounts</p>
                @forelse ($userStatuses as $status)
                    <div class="admin-list-row">                    <span>{{ $status->status instanceof \App\Enums\UserStatus ? $status->status->label() : str_replace('_', ' ', ucfirst($status->status)) }}</span><strong>{{ number_format($status->total) }}</strong></div>
                @empty<p class="admin-empty">No user accounts found.</p>@endforelse
            </section>
        </div>
        <section class="admin-panel"><h2>Top products</h2><p class="admin-subtitle">Ranked by units sold</p>
            <div class="admin-table-wrap"><table class="admin-table"><thead><tr><th>Product</th><th>Units sold</th><th>Revenue</th></tr></thead>
                <tbody>@forelse ($topProducts as $product)<tr><td>{{ $product->name }}</td><td>{{ number_format($product->units_sold) }}</td><td>₱{{ number_format($product->revenue, 2) }}</td></tr>@empty<tr><td colspan="3" class="admin-empty">There are no product sales yet.</td></tr>@endforelse</tbody>
            </table></div>
        </section>
    </section>
@endsection
