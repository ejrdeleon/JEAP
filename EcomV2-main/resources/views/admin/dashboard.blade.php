@extends('layouts.dashboard')
@section('title', 'Admin')
@section('nav')
    <a class="active" href="{{ route('admin.dashboard') }}">Overview</a>
    <a href="{{ route('admin.verifications') }}">Verifications</a>
    <a href="{{ route('admin.cms') }}">Marketplace CMS</a>
    <a href="{{ route('admin.users') }}">Users</a>
    <a href="{{ route('admin.disputes') }}">Disputes</a>
    <a href="{{ route('admin.contact-messages') }}">Contact messages</a>
    <a href="{{ route('admin.reports') }}">Reports</a>
    @if (auth()->user()->hasRole('super-admin'))
        <a href="{{ route('super-admin.dashboard') }}">Super admin</a>
    @endif
@endsection
@section('content')
    <section class="admin-page">
        <header class="admin-heading">
            <div><h1>Admin dashboard</h1><p>Registrations, orders, and the {{ number_format($commissionRate, 0) }}% logistics commission on merchandise.</p></div>
            <a class="admin-button" href="{{ route('admin.verifications') }}">Review registrations</a>
        </header>
        <div class="admin-stats">
            <article><span>Pending registrations</span><strong>{{ number_format($pendingCount) }}</strong><a href="{{ route('admin.verifications') }}">Review queue</a></article>
            <article><span>Active marketplace users</span><strong>{{ number_format($activeUsers) }}</strong><a href="{{ route('admin.users') }}">Manage users</a></article>
            <article><span>Orders today</span><strong>{{ number_format($ordersToday) }}</strong><a href="{{ route('admin.reports') }}">View reports</a></article>
            <article><span>Sales this month</span><strong>₱{{ number_format($salesThisMonth, 2) }}</strong><a href="{{ route('admin.reports') }}">View analytics</a></article>
            <article><span>Logistics commission</span><strong>₱{{ number_format($logisticsCommission, 2) }}</strong><a href="{{ route('admin.reports') }}">{{ number_format($commissionRate, 0) }}% of merchandise</a></article>
        </div>
        <section class="admin-panel">
            <div class="admin-panel-heading"><div><h2>Recent orders</h2><p>Latest marketplace transactions</p></div><a href="{{ route('admin.disputes') }}">{{ number_format($openDisputes) }} open disputes</a></div>
            <div class="admin-table-wrap"><table class="admin-table">
                <thead><tr><th>Order</th><th>Buyer</th><th>Seller</th><th>Status</th><th>Total</th><th>Date</th></tr></thead>
                <tbody>@forelse ($recentOrders as $order)
                    <tr><td>{{ $order->order_number }}</td><td>{{ $order->buyer?->name ?? '—' }}</td><td>{{ $order->seller?->name ?? '—' }}</td><td><span class="admin-pill">{{ $order->status->value }}</span></td><td>₱{{ number_format($order->total, 2) }}</td><td>{{ $order->created_at->format('M j, Y') }}</td></tr>
                @empty<tr><td colspan="6" class="admin-empty">No orders have been placed yet.</td></tr>@endforelse</tbody>
            </table></div>
        </section>
    </section>
@endsection
