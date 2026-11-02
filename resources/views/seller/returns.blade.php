@extends('layouts.dashboard')
@section('title', 'Returns')
@section('nav')
    @include('partials.seller-nav', ['active' => 'returns'])
@endsection
@section('content')
<div class="seller-page">
    <div class="seller-heading"><div><h1>Return requests</h1><p>Approve a return to mark the order returned and void the logistics cut. Reject it if the request is not valid.</p></div></div>
    @if(session('status'))<p class="admin-notice">{{ session('status') }}</p>@endif
    @if($errors->any())<p class="seller-errors">{{ $errors->first() }}</p>@endif
    <section class="seller-panel">
        @forelse($returns as $return)
            <article class="admin-record">
                <div class="admin-record-head"><div><h2>{{ $return->order?->order_number }}</h2><p>{{ str($return->reason)->replace('_', ' ')->title() }} · {{ $return->buyer?->name }} · {{ $return->created_at->format('M j, Y') }}</p></div><span class="seller-badge">{{ $return->status }}</span></div>
                @if($return->description)<p>{{ $return->description }}</p>@endif
                @if($return->status === 'pending')
                    <form method="post" action="{{ route('seller.returns.decide', $return) }}" class="admin-inline-form">
                        @csrf
                        <label class="admin-field"><span>Notes</span><input name="notes" maxlength="500"></label>
                        <button class="seller-primary" name="decision" value="approved">Approve</button>
                        <button class="seller-secondary" name="decision" value="rejected">Reject</button>
                    </form>
                @elseif($return->admin_notes)<p class="admin-meta">{{ $return->admin_notes }}</p>
                @endif
            </article>
        @empty
            <div class="seller-empty"><strong>No return requests</strong><p>Buyer return requests for your orders will show up here.</p></div>
        @endforelse
        <div class="seller-pagination">{{ $returns->links() }}</div>
    </section>
</div>
@endsection
