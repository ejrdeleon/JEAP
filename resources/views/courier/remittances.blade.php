@extends('layouts.dashboard')
@section('title', 'COD remittance')
@section('nav')
    <a href="{{ route('courier.dashboard') }}">Rider dashboard</a>
    <a class="active" href="{{ route('courier.remittances') }}">COD remittance</a>
@endsection
@section('content')
@php
    $pendingCash = $pendingOrders->sum(fn ($order) => (float) $order->total);
    $submittedCount = $history->total();
@endphp
<div class="rider-dashboard remit-page">
    <header class="rider-dashboard-heading">
        <div>
            <span class="buyer-home-eyebrow">{{ strtoupper(config('jeap.courier_name')) }} RIDER</span>
            <h1>COD remittance</h1>
            <p>Turn in Cash on Delivery from completed jobs to your sorting center. When the hub confirms the cash, the seller’s logistics cut on those orders is marked paid.</p>
        </div>
    </header>
    @if(session('status'))<div class="buyer-home-flash" role="status">{{ session('status') }}</div>@endif
    @if($errors->any())<div class="buyer-home-flash rider-error" role="alert">{{ $errors->first() }}</div>@endif

    <div class="rider-summary remit-summary">
        <article><span>Cash to turn in</span><strong>₱{{ number_format($pendingCash, 2) }}</strong></article>
        <article><span>Unremitted orders</span><strong>{{ $pendingOrders->count() }}</strong></article>
        <article><span>Submitted</span><strong>{{ $submittedCount }}</strong></article>
    </div>

    <section class="rider-panel">
        <div class="rider-panel-heading">
            <div>
                <span class="buyer-home-eyebrow">CASH ON HAND</span>
                <h2>Unremitted orders</h2>
            </div>
            <span>{{ $pendingOrders->count() }} {{ Str::plural('order', $pendingOrders->count()) }}</span>
        </div>
        @if($pendingOrders->isEmpty())
            <div class="remit-empty">
                <span aria-hidden="true">₱</span>
                <strong>No cash to turn in</strong>
                <p>Completed Cash on Delivery jobs appear here. Submit them after you finish the last-mile drop.</p>
            </div>
        @else
            <form method="post" action="{{ route('courier.remittances.store') }}" class="remit-form" data-remit-form>
                @csrf
                <div class="remit-orders">
                    @foreach($pendingOrders as $order)
                        <label class="remit-order">
                            <input type="checkbox" name="order_ids[]" value="{{ $order->id }}" data-amount="{{ (float) $order->total }}" checked>
                            <span class="remit-order-copy">
                                <strong>{{ $order->order_number }}</strong>
                                <small>Cash on Delivery collected</small>
                            </span>
                            <span class="remit-order-amount">₱{{ number_format((float) $order->total, 2) }}</span>
                        </label>
                    @endforeach
                </div>
                <label class="remit-notes">Notes <span>(optional)</span>
                    <input name="notes" value="{{ old('notes') }}" maxlength="500" placeholder="Hub desk, shift, or envelope number">
                </label>
                <div class="remit-actions">
                    <p data-remit-total>Turning in ₱{{ number_format($pendingCash, 2) }} from {{ $pendingOrders->count() }} {{ Str::plural('order', $pendingOrders->count()) }}.</p>
                    <button class="remit-submit" type="submit">Submit remittance</button>
                </div>
            </form>
        @endif
    </section>

    <section class="rider-panel">
        <div class="rider-panel-heading">
            <div>
                <span class="buyer-home-eyebrow">SORTING CENTER</span>
                <h2>History</h2>
            </div>
            <span>{{ $submittedCount }} {{ Str::plural('remittance', $submittedCount) }}</span>
        </div>
        @forelse($history as $remittance)
            <article class="remit-history">
                <div class="remit-history-head">
                    <div>
                        <strong>₱{{ number_format((float) $remittance->amount, 2) }}</strong>
                        <p>{{ $remittance->created_at->timezone(config('app.timezone'))->format('M j, Y · g:i A') }}</p>
                    </div>
                    <span class="remit-status {{ $remittance->status === 'confirmed' ? 'is-confirmed' : 'is-pending' }}">{{ $remittance->status === 'confirmed' ? 'Confirmed' : 'Waiting for hub' }}</span>
                </div>
                <p>{{ $remittance->orders->count() }} {{ Str::plural('order', $remittance->orders->count()) }}{{ $remittance->orders->isNotEmpty() ? ' · '.$remittance->orders->pluck('order_number')->join(', ') : '' }}</p>
                @if($remittance->notes)<p>{{ $remittance->notes }}</p>@endif
                @if($remittance->status === 'confirmed' && $remittance->remitted_at)
                    <p class="remit-history-meta">Hub confirmed {{ $remittance->remitted_at->timezone(config('app.timezone'))->format('M j, Y · g:i A') }}</p>
                @endif
            </article>
        @empty
            <div class="remit-empty">
                <span aria-hidden="true">↓</span>
                <strong>No remittances yet</strong>
                <p>After you submit cash, the sorting center confirms it here.</p>
            </div>
        @endforelse
        @if($history->hasPages())
            <div class="remit-pagination">{{ $history->links() }}</div>
        @endif
    </section>
</div>
@endsection
