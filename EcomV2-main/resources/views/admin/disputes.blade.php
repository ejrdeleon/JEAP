@extends('layouts.dashboard')
@section('title', 'Disputes')
@section('nav')
    <a href="{{ route('admin.dashboard') }}">Overview</a>
    <a href="{{ route('admin.verifications') }}">Verifications</a>
    <a href="{{ route('admin.cms') }}">Marketplace CMS</a>
    <a href="{{ route('admin.users') }}">Users</a>
    <a class="active" href="{{ route('admin.disputes') }}">Disputes</a>
    <a href="{{ route('admin.reports') }}">Reports</a>
    @if (auth()->user()->hasRole('super-admin')) <a href="{{ route('super-admin.dashboard') }}">Super admin</a> @endif
@endsection
@section('content')
    <section class="admin-page">
        <header class="admin-heading"><div><span class="admin-eyebrow">CUSTOMER SUPPORT</span><h1>Disputes</h1><p>Review complaints and record their resolution status.</p></div></header>
        @if (session('status')) <p class="admin-notice">{{ session('status') }}</p> @endif
        @if ($errors->any()) <p class="admin-error">{{ $errors->first() }}</p> @endif
        <section class="admin-panel">
            @forelse ($complaints as $complaint)
                <article class="admin-record">
                    <div class="admin-record-head"><div><h2>{{ $complaint->type ?: 'Marketplace complaint' }}</h2><p>Submitted by {{ $complaint->complainant?->name ?? 'Unknown user' }} · {{ $complaint->created_at->format('M j, Y H:i') }}</p></div><span class="admin-pill">{{ str_replace('_', ' ', ucfirst($complaint->status)) }}</span></div>
                    <p class="admin-complaint-body">{{ $complaint->body }}</p>
                    <p class="admin-meta">Against: {{ $complaint->againstUser?->name ?? 'Not specified' }} · Order: {{ $complaint->order?->order_number ?? 'Not linked' }}</p>
                    <form method="post" action="{{ route('admin.disputes.update', $complaint) }}" class="admin-inline-form">
                        @csrf @method('PATCH')
                        <label class="admin-field"><span>Resolution status</span><select name="status"><option value="open" @selected($complaint->status === 'open')>Open</option><option value="under_review" @selected($complaint->status === 'under_review')>Under review</option><option value="resolved" @selected($complaint->status === 'resolved')>Resolved</option><option value="rejected" @selected($complaint->status === 'rejected')>Rejected</option></select></label>
                        <button class="admin-button admin-button-small">Update status</button>
                    </form>
                </article>
            @empty<p class="admin-empty">No complaints have been submitted.</p>@endforelse
            <div class="admin-pagination">{{ $complaints->links() }}</div>
        </section>
    </section>
@endsection
