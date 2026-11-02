@extends('layouts.dashboard')
@section('title', 'Returns')
@section('nav')
    @include('partials.admin-nav', ['active' => 'returns'])
@endsection
@section('content')
<section class="admin-page">
    <header class="admin-heading"><div><span class="admin-eyebrow">AFTER SALE</span><h1>Returns</h1><p>Approve or reject buyer return requests. An approved return voids the logistics commission.</p></div></header>
    @if(session('status'))<p class="admin-notice">{{ session('status') }}</p>@endif
    @if($errors->any())<p class="admin-error">{{ $errors->first() }}</p>@endif
    <section class="admin-panel">
        @forelse($returns as $return)
            <article class="admin-record">
                <div class="admin-record-head"><div><h2>{{ $return->order?->order_number }}</h2><p>{{ $return->buyer?->name }} → {{ $return->seller?->name }} · {{ str($return->reason)->replace('_', ' ')->title() }}</p></div><span class="admin-pill">{{ $return->status }}</span></div>
                @if($return->description)<p class="admin-complaint-body">{{ $return->description }}</p>@endif
                @if($return->status === 'pending')
                    <form method="post" action="{{ route('admin.returns.decide', $return) }}" class="admin-inline-form">
                        @csrf
                        <label class="admin-field"><span>Notes</span><input name="notes" maxlength="500"></label>
                        <button class="admin-button admin-button-small" name="decision" value="approved">Approve</button>
                        <button class="admin-button admin-button-secondary" name="decision" value="rejected">Reject</button>
                    </form>
                @endif
            </article>
        @empty<p class="admin-empty">No return requests.</p>@endforelse
        <div class="admin-pagination">{{ $returns->links() }}</div>
    </section>
</section>
@endsection
