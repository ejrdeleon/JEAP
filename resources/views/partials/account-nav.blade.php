<nav class="account-links">
    <a class="{{ request()->routeIs('profile') ? 'is-current' : '' }}" href="{{ route('profile') }}" @if(request()->routeIs('profile')) aria-current="page" @endif>Profile</a>
    <a class="{{ request()->routeIs('buyer.home') ? 'is-current' : '' }}" href="{{ route('buyer.home') }}">My orders</a>
    @if($user->hasRole('buyer'))
        <a class="{{ request()->routeIs('buyer.addresses') ? 'is-current' : '' }}" href="{{ route('buyer.addresses') }}">Addresses</a>
        <a class="{{ request()->routeIs('buyer.wishlist') ? 'is-current' : '' }}" href="{{ route('buyer.wishlist') }}">Wishlist</a>
    @endif
    <a class="{{ request()->routeIs('chat.*') ? 'is-current' : '' }}" href="{{ route('chat.index') }}">Chat</a>
    <a class="{{ request()->routeIs('notifications.index') ? 'is-current' : '' }}" href="{{ route('notifications.index') }}">Notifications</a>
    <a class="{{ request()->routeIs('account.password') ? 'is-current' : '' }}" href="{{ route('account.password') }}">Change password</a>
    <a class="{{ request()->routeIs('account.notification-settings') ? 'is-current' : '' }}" href="{{ route('account.notification-settings') }}">Notification settings</a>
    @if($user->hasRole('seller'))
        <a href="{{ route('seller.dashboard') }}">Seller centre</a>
    @elseif($user->hasRole('buyer'))
        <a href="{{ route('register.seller') }}">Start selling</a>
    @endif
</nav>
