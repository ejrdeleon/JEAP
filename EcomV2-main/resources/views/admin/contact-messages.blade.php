@extends('layouts.dashboard')
@section('title', 'Contact messages')
@section('nav')
    <a href="{{ route('admin.dashboard') }}">Overview</a>
    <a href="{{ route('admin.verifications') }}">Verifications</a>
    <a href="{{ route('admin.cms') }}">Marketplace CMS</a>
    <a href="{{ route('admin.users') }}">Users</a>
    <a href="{{ route('admin.disputes') }}">Disputes</a>
    <a class="active" href="{{ route('admin.contact-messages') }}">Contact messages</a>
    <a href="{{ route('admin.reports') }}">Reports</a>
    @if (auth()->user()->hasRole('super-admin')) <a href="{{ route('super-admin.dashboard') }}">Super admin</a> @endif
@endsection
@section('content')
    <section class="admin-page">
        <header class="admin-heading"><div><span class="admin-eyebrow">CUSTOMER SUPPORT</span><h1>Contact messages</h1><p>Messages submitted through the public JEAP contact form.</p></div></header>
        <section class="admin-panel">
            @forelse ($messages as $message)
                <article class="admin-record">
                    <div class="admin-record-head"><div><h2>{{ $message->full_name }}</h2><p><a href="mailto:{{ $message->email }}">{{ $message->email }}</a> · {{ $message->created_at->format('M j, Y H:i') }}</p></div><span class="admin-pill">{{ ucfirst($message->category) }}</span></div>
                    @if ($message->order_number)<p class="admin-meta">Order: {{ $message->order_number }}</p>@endif
                    <p class="admin-complaint-body">{{ $message->message }}</p>
                </article>
            @empty
                <p class="admin-empty">No contact messages have been submitted.</p>
            @endforelse
            <div class="admin-pagination">{{ $messages->links() }}</div>
        </section>
    </section>
@endsection
