@extends('layouts.storefront')

@section('title', 'Notifications | JEAP')
@section('crumb')
    <span>My account</span><span>/</span><span>Notifications</span>
@endsection

@section('content')
<div class="account-page">
    <header class="chat-page-heading">
        <div>
            <span class="account-eyebrow">MY JEAP ACCOUNT</span>
            <h1>Notifications</h1>
            <p>Order, account, and promo alerts. Chat messages stay in Chat.</p>
        </div>
        <div class="notice-heading-actions">
            <a class="chat-page-switch" href="{{ route('chat.index') }}">Open chat</a>
            @if(auth()->user()->unreadActivityNotificationCount() > 0)
                <form method="post" action="{{ route('notifications.read') }}">@csrf<button class="notice-mark-all" type="submit">Mark all as read</button></form>
            @endif
        </div>
    </header>
    <div class="account-page-layout">
        <aside class="account-side-card">
            <strong>{{ auth()->user()->name }}</strong>
            @include('partials.account-nav', ['user' => auth()->user()])
        </aside>
        <section class="notice-feed">
            @forelse($notifications as $notification)
                @php
                    $type = class_basename((string) $notification->type);
                    $kind = match (true) {
                        str_contains($type, 'Order') => 'order',
                        str_contains($type, 'Rider') => 'rider',
                        str_contains($type, 'Voucher'), str_contains($type, 'Promo') => 'promo',
                        default => 'account',
                    };
                    $title = $notification->data['title'] ?? 'JEAP';
                    $body = $notification->data['body'] ?? '';
                    $openUrl = route('notifications.open', $notification);
                @endphp
                <article class="notice-item {{ $notification->read_at ? '' : 'is-unread' }}" data-notice-kind="{{ $kind }}">
                    <span class="notice-icon" aria-hidden="true"></span>
                    <div class="notice-copy">
                        <a class="notice-title" href="{{ $openUrl }}">{{ $title }}</a>
                        @if($body !== '')<p>{{ $body }}</p>@endif
                        <time>{{ $notification->created_at?->timezone(config('app.timezone'))->format('M j, Y · g:i A') }}</time>
                    </div>
                    <div class="notice-row-actions">
                        <a href="{{ $openUrl }}">Open</a>
                        @if(! $notification->read_at)
                            <form method="post" action="{{ route('notifications.read') }}">@csrf<input type="hidden" name="id" value="{{ $notification->id }}"><button type="submit">Read</button></form>
                        @endif
                    </div>
                </article>
            @empty
                <div class="notice-empty">
                    <strong>You’re all caught up</strong>
                    <p>New order and account updates will show up here. Chats are in a separate inbox.</p>
                    <a href="{{ route('chat.index') }}">Go to chat</a>
                </div>
            @endforelse
            {{ $notifications->links() }}
        </section>
    </div>
</div>
@endsection
