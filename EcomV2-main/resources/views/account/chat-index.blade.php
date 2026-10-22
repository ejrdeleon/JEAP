@extends('layouts.storefront')

@section('title', 'Chat | JEAP')
@section('crumb')
    <span>My account</span><span>/</span><span>Chat</span>
@endsection

@section('content')
<div class="account-page">
    <header class="account-page-heading"><div><span class="account-eyebrow">MY JEAP ACCOUNT</span><h1>Chat</h1><p>Message buyers, sellers, and riders about an order.</p></div></header>
    <div class="chat-shell">
        <aside class="chat-list">
            @forelse($conversations as $conversation)
                <a class="chat-list-item {{ $conversation->unread_count ? 'is-unread' : '' }}" href="{{ route('chat.show', $conversation) }}">
                    <strong>{{ $conversation->counterpart?->name ?? $conversation->subject ?? 'JEAP chat' }}</strong>
                    <p>{{ $conversation->latestMessage?->body ?? 'No messages yet' }}</p>
                    <small>{{ $conversation->order?->order_number }}</small>
                </a>
            @empty
                <p class="buyer-track-note">No chats yet. Open an order and start a conversation from tracking.</p>
            @endforelse
        </aside>
        <section class="chat-empty-pane">
            <p>Select a conversation, or open an order to message the other party.</p>
        </section>
    </div>
</div>
@endsection
