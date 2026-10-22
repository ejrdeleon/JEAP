@extends('layouts.storefront')

@section('title', 'Notifications | JEAP')
@section('crumb')
    <span>My account</span><span>/</span><span>Notifications</span>
@endsection

@section('content')
<div class="account-page">
    <header class="account-page-heading">
        <div><span class="account-eyebrow">MY JEAP ACCOUNT</span><h1>Notifications</h1><p>Order, chat, and account updates in one place.</p></div>
        @if(auth()->user()->unreadNotifications()->exists())
            <form method="post" action="{{ route('notifications.read') }}">@csrf<button class="account-logout" type="submit">Mark all as read</button></form>
        @endif
    </header>
    <div class="account-page-layout">
        <aside class="account-side-card">
            <strong>{{ auth()->user()->name }}</strong>
            @include('partials.account-nav', ['user' => auth()->user()])
        </aside>
        <section class="account-form-card">
            @forelse($notifications as $notification)
                <article class="notice-row {{ $notification->read_at ? '' : 'is-unread' }}">
                    <div>
                        <strong>{{ $notification->data['title'] ?? 'JEAP' }}</strong>
                        <p>{{ $notification->data['body'] ?? '' }}</p>
                        <small>{{ $notification->created_at?->timezone(config('app.timezone'))->format('M j, Y · g:i A') }}</small>
                    </div>
                    <div class="notice-row-actions">
                        @if(! empty($notification->data['url']))<a href="{{ $notification->data['url'] }}">Open</a>@endif
                        @if(! $notification->read_at)
                            <form method="post" action="{{ route('notifications.read') }}">@csrf<input type="hidden" name="id" value="{{ $notification->id }}"><button type="submit">Read</button></form>
                        @endif
                    </div>
                </article>
            @empty
                <p class="buyer-track-note">You’re all caught up.</p>
            @endforelse
            {{ $notifications->links() }}
        </section>
    </div>
</div>
@endsection
