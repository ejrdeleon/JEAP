@extends('layouts.dashboard')
@section('title', 'Contact messages')
@section('nav')
    @include('partials.admin-nav', ['active' => 'contact'])
@endsection
@section('content')
    <section class="admin-page">
        <header class="admin-heading"><div><span class="admin-eyebrow">CUSTOMER SUPPORT</span><h1>Contact messages</h1><p>Messages submitted through the public JEAP contact form.</p></div></header>
        @if (session('status')) <p class="admin-notice">{{ session('status') }}</p> @endif
        @if ($errors->any()) <p class="admin-error">{{ $errors->first() }}</p> @endif
        <section class="admin-panel">
            @forelse ($messages as $message)
                <article class="admin-record">
                    <div class="admin-record-head"><div><h2>{{ $message->full_name }}</h2><p><a href="mailto:{{ $message->email }}">{{ $message->email }}</a> · {{ $message->created_at->format('M j, Y H:i') }}</p></div><span class="admin-pill">{{ $message->replied_at ? 'Replied' : ucfirst($message->category) }}</span></div>
                    @if ($message->order_number)<p class="admin-meta">Order: {{ $message->order_number }}</p>@endif
                    <p class="admin-complaint-body">{{ $message->message }}</p>
                    @if($message->admin_reply)<p class="admin-meta">Saved reply ({{ $message->replied_at?->format('M j, Y') }}): {{ $message->admin_reply }}</p>@endif
                    <form method="post" action="{{ route('admin.contact-messages.reply', $message) }}" class="admin-inline-form">
                        @csrf
                        <label class="admin-field"><span>Reply to keep on file</span><textarea name="admin_reply" rows="2" maxlength="5000" required>{{ old('admin_reply', $message->admin_reply) }}</textarea></label>
                        <button class="admin-button admin-button-small">Save reply</button>
                        <a class="admin-button admin-button-secondary" href="mailto:{{ $message->email }}">Open email</a>
                    </form>
                </article>
            @empty
                <p class="admin-empty">No contact messages have been submitted.</p>
            @endforelse
            <div class="admin-pagination">{{ $messages->links() }}</div>
        </section>
    </section>
@endsection
