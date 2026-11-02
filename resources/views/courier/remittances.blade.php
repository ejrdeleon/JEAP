@extends('layouts.dashboard')
@section('title', 'COD remittance')
@section('nav')
    <a href="{{ route('courier.dashboard') }}">Rider dashboard</a>
    <a class="active" href="{{ route('courier.remittances') }}">COD remittance</a>
@endsection
@section('content')
<div class="seller-page">
    <div class="seller-heading"><div><h1>Cash on Delivery to remit</h1><p>Turn in cash for completed deliveries to your sorting center. Confirmed remittances mark the seller’s logistics cut as paid.</p></div></div>
    @if(session('status'))<p class="admin-notice">{{ session('status') }}</p>@endif
    @if($errors->any())<p class="seller-errors">{{ $errors->first() }}</p>@endif
    <section class="seller-panel">
        <h2>Unremitted orders</h2>
        @if($pendingOrders->isEmpty())
            <p class="rider-empty">No completed deliveries are waiting to be remitted.</p>
        @else
            <form method="post" action="{{ route('courier.remittances.store') }}">
                @csrf
                @foreach($pendingOrders as $order)
                    <label class="register-terms"><input type="checkbox" name="order_ids[]" value="{{ $order->id }}" checked> {{ $order->order_number }} · ₱{{ number_format((float) $order->total, 2) }}</label>
                @endforeach
                <div class="s3-field"><label>Notes (optional)</label><input name="notes" maxlength="500"></div>
                <button class="seller-primary" type="submit">Submit remittance</button>
            </form>
        @endif
    </section>
    <section class="seller-panel">
        <h2>History</h2>
        @forelse($history as $remittance)
            <p>{{ $remittance->created_at->format('M j, Y') }} · ₱{{ number_format((float) $remittance->amount, 2) }} · {{ $remittance->status }} · {{ $remittance->orders->count() }} orders</p>
        @empty
            <p class="rider-empty">No remittances yet.</p>
        @endforelse
        {{ $history->links() }}
    </section>
</div>
@endsection
