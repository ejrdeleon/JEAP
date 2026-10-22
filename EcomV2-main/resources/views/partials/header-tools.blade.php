<div class="header-icons">
    @auth
        <a class="header-tool" href="{{ route('chat.index') }}" aria-label="Chat">
            <svg viewBox="0 0 24 24" fill="none" aria-hidden="true"><path d="M5 6.75A2.75 2.75 0 0 1 7.75 4h8.5A2.75 2.75 0 0 1 19 6.75v6.5A2.75 2.75 0 0 1 16.25 16H12l-3.6 3.15A.75.75 0 0 1 7 18.6V16H7.75A2.75 2.75 0 0 1 5 13.25v-6.5Z" stroke="currentColor" stroke-width="1.7" stroke-linejoin="round"/></svg>
            @if(($unreadChatCount ?? 0) > 0)<span class="header-badge">{{ $unreadChatCount > 9 ? '9+' : $unreadChatCount }}</span>@endif
        </a>
        <a class="header-tool" href="{{ route('notifications.index') }}" aria-label="Notifications">
            <svg viewBox="0 0 24 24" fill="none" aria-hidden="true"><path d="M6.5 9.5a5.5 5.5 0 1 1 11 0c0 3.2 1.1 4.7 1.8 5.5H4.7c.7-.8 1.8-2.3 1.8-5.5Z" stroke="currentColor" stroke-width="1.7" stroke-linejoin="round"/><path d="M10 18.5a2 2 0 0 0 4 0" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/></svg>
            @if(($unreadNotificationCount ?? 0) > 0)<span class="header-badge">{{ $unreadNotificationCount > 9 ? '9+' : $unreadNotificationCount }}</span>@endif
        </a>
    @endauth
    <a class="header-tool" href="{{ auth()->check() ? route('profile') : route('login') }}" aria-label="Account">
        <svg viewBox="0 0 24 24" fill="none" aria-hidden="true"><circle cx="12" cy="8" r="3.25" stroke="currentColor" stroke-width="1.7"/><path d="M5.8 18.4a6.5 6.5 0 0 1 12.4 0" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/></svg>
    </a>
    <a class="header-tool" href="{{ route('cart.index') }}" aria-label="Cart">
        <svg viewBox="0 0 24 24" fill="none" aria-hidden="true"><path d="M4.5 6.5h1.7l.6 2.2 1.2 7.1h9.6l1.6-6.3H8" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/><circle cx="10" cy="18.2" r="1.2" fill="currentColor"/><circle cx="16.4" cy="18.2" r="1.2" fill="currentColor"/></svg>
        <span class="cart-count">{{ $cartCount ?? 0 }}</span>
    </a>
    <button type="button" class="nav-toggle" data-nav-toggle aria-expanded="false" aria-controls="site-nav">Menu</button>
</div>
