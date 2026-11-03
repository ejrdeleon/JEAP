@extends('layouts.storefront')

@php
    $viewer = auth()->user();
    $active = $conversation ?? null;
@endphp

@section('title', ($active ? $active->counterpartLabel($viewer) : 'Chat').' | JEAP')
@section('crumb')
    <span>My account</span><span>/</span><span>Chat</span>
@endsection

@section('content')
<div class="account-page chat-page {{ $active ? 'has-thread' : '' }}" data-chat-page>
    <header class="chat-page-heading">
        <div>
            <span class="account-eyebrow">MY JEAP ACCOUNT</span>
            <h1>Chat</h1>
            <p>Message sellers, buyers, and riders. Order and account alerts stay in Notifications.</p>
        </div>
        <a class="chat-page-switch" href="{{ route('notifications.index') }}">Open notifications</a>
    </header>

    <div class="chat-shell">
        <aside class="chat-list">
            <div class="chat-list-toolbar">
                <label class="visually-hidden" for="chat-search">Search conversations</label>
                <input id="chat-search" type="search" data-chat-search placeholder="Search chats" autocomplete="off">
            </div>
            <div class="chat-list-scroll">
                @forelse($conversations as $item)
                    @php
                        $itemName = $item->counterpartLabel($viewer);
                        $itemRole = $item->counterpartRole($viewer);
                        $preview = $item->latestMessage?->body ?? 'No messages yet';
                    @endphp
                    <a class="chat-list-item {{ $active && $item->id === $active->id ? 'is-current' : '' }} {{ $item->unread_count ? 'is-unread' : '' }}"
                        href="{{ route('chat.show', $item) }}"
                        data-chat-item
                        data-search="{{ strtolower($itemName.' '.$itemRole.' '.$preview.' '.($item->order?->order_number ?? '')) }}">
                        @include('partials.chat-avatar', ['person' => $item->counterpartFor($viewer), 'label' => $itemName])
                        <span class="chat-list-copy">
                            <span class="chat-list-row">
                                <strong>{{ $itemName }}</strong>
                                <time>{{ \App\Models\Conversation::stamp($item->latestMessage?->created_at) }}</time>
                            </span>
                            <span class="chat-list-meta">{{ $itemRole }}@if($item->order) · {{ $item->order->order_number }}@endif</span>
                            <p>{{ $preview }}</p>
                        </span>
                        @if($item->unread_count)
                            <span class="chat-unread">{{ $item->unread_count > 9 ? '9+' : $item->unread_count }}</span>
                        @endif
                    </a>
                @empty
                    <div class="chat-list-empty">
                        <strong>No chats yet</strong>
                        <p>Open an order or a shop page and start a conversation from there.</p>
                    </div>
                @endforelse
                <p class="chat-list-empty" data-chat-search-empty hidden>No chats match that search.</p>
            </div>
        </aside>

        @if($active)
            @php
                $peer = $active->counterpartFor($viewer);
                $peerName = $active->counterpartLabel($viewer);
                $peerRole = $active->counterpartRole($viewer);
                $orderUrl = $active->orderUrlFor($viewer);
                $lastDate = null;
            @endphp
            <section class="chat-thread" data-chat-thread data-conversation="{{ $active->id }}" data-poll="{{ route('chat.messages', $active) }}">
                <header class="chat-thread-head">
                    <a class="chat-back" href="{{ route('chat.index') }}">Back to chats</a>
                    @include('partials.chat-avatar', ['person' => $peer, 'label' => $peerName])
                    <div>
                        <strong>{{ $peerName }}</strong>
                        <p>{{ $peerRole }}@if($active->order) · {{ $active->order->order_number }}@endif</p>
                    </div>
                    @if($orderUrl)
                        <a class="chat-order-link" href="{{ $orderUrl }}">View order</a>
                    @endif
                </header>
                <div class="chat-messages" data-chat-log aria-live="polite">
                    @forelse($active->messages as $message)
                        @php
                            $day = $message->created_at?->timezone(config('app.timezone'))->toDateString();
                        @endphp
                        @if($day && $day !== $lastDate)
                            <div class="chat-day" data-chat-day="{{ $day }}">{{ $message->created_at->timezone(config('app.timezone'))->format('M j, Y') }}</div>
                            @php $lastDate = $day; @endphp
                        @endif
                        <div class="chat-bubble {{ $message->user_id === $viewer->id ? 'is-mine' : '' }}" data-message-id="{{ $message->id }}">
                            @unless($message->user_id === $viewer->id)<small>{{ $message->sender?->name }}</small>@endunless
                            <p>{{ $message->body }}</p>
                            <time>{{ $message->created_at?->timezone(config('app.timezone'))->format('g:i A') }}</time>
                        </div>
                    @empty
                        <p class="chat-thread-empty">No messages yet. Say hello to start this conversation.</p>
                    @endforelse
                </div>
                <form class="chat-compose" method="post" action="{{ route('chat.send', $active) }}" data-chat-form>
                    @csrf
                    <label class="visually-hidden" for="chat-message">Message</label>
                    <textarea id="chat-message" name="message" rows="1" maxlength="{{ config('jeap.chat_message_max') }}" required placeholder="Write a message" data-chat-input></textarea>
                    <button type="submit">Send</button>
                </form>
            </section>
        @else
            <section class="chat-empty-pane">
                <strong>Select a conversation</strong>
                <p>Pick a chat on the left, or open an order to message the other party.</p>
            </section>
        @endif
    </div>
</div>
@endsection
