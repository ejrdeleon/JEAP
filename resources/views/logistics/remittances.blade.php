@extends('layouts.dashboard')
@section('title', 'COD remittances')
@section('nav')
    @include('partials.logistics-nav')
@endsection
@section('content')
<div class="shipment-page">
    <header class="shipment-heading"><div><h1>Rider remittances</h1><p>Confirm cash received from riders. That marks the logistics commission on those orders as paid to the platform and due as seller payout.</p></div></header>
    @if(session('status'))<div class="shipment-notice is-success">{{ session('status') }}</div>@endif
    @if($errors->any())<div class="shipment-notice is-error">{{ $errors->first() }}</div>@endif
    @forelse($remittances as $remittance)
        <article class="admin-record">
            <div class="admin-record-head"><div><h2>{{ $remittance->courier?->name }}</h2><p>₱{{ number_format((float) $remittance->amount, 2) }} · {{ $remittance->orders->pluck('order_number')->join(', ') }}</p></div><span class="admin-pill">{{ $remittance->status }}</span></div>
            @if($remittance->notes)<p>{{ $remittance->notes }}</p>@endif
            @if($remittance->status === 'pending')
                <form method="post" action="{{ route('logistics.remittances.confirm', $remittance) }}">@csrf<button class="seller-primary" type="submit">Confirm cash received</button></form>
            @else
                <p class="admin-meta">Confirmed {{ $remittance->remitted_at?->format('M j, Y H:i') }}</p>
            @endif
        </article>
    @empty
        <p class="rider-empty">No remittances submitted yet.</p>
    @endforelse
    {{ $remittances->links() }}
</div>
@endsection
