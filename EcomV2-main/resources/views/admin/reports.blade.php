@extends('layouts.dashboard')
@section('title', 'Reports')
@section('nav')
    <a href="{{ route('admin.dashboard') }}">Overview</a>
    <a href="{{ route('admin.verifications') }}">Verifications</a>
    <a href="{{ route('admin.cms') }}">Marketplace CMS</a>
    <a href="{{ route('admin.users') }}">Users</a>
    <a href="{{ route('admin.disputes') }}">Disputes</a>
    <a class="active" href="{{ route('admin.reports') }}">Reports</a>
    @if (auth()->user()->hasRole('super-admin')) <a href="{{ route('super-admin.dashboard') }}">Super admin</a> @endif
@endsection
@section('content')
    <section class="admin-page">
        <header class="admin-heading"><div><span class="admin-eyebrow">MARKETPLACE ANALYTICS</span><h1>Reports</h1><p>Order, sales, and account activity across JEAP.</p></div></header>
        <div class="admin-stats admin-stats-three">
            <article><span>Total orders</span><strong>{{ number_format($totalOrders) }}</strong></article>
            <article><span>Gross sales</span><strong>₱{{ number_format($grossSales, 2) }}</strong></article>
            <article><span>Active marketplace users</span><strong>{{ number_format($activeUsers) }}</strong></article>
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
