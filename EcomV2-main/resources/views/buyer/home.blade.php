@extends('layouts.storefront')

@section('title', 'My JEAP | Orders and account')
@section('content')
<div class="buyer-home" data-figma="01_Buyer_Home 1">
    <header class="buyer-home-heading">
        <div>
            <span class="buyer-home-eyebrow">MY JEAP ACCOUNT</span>
            <h1>Hello{{ auth()->user()?->first_name ? ', '.auth()->user()->first_name : '' }}</h1>
            <p>Keep up with your orders and manage your delivery details.</p>
        </div>
        <a class="buyer-home-shop" href="{{ route('products.index') }}">Continue shopping <span aria-hidden="true">→</span></a>
    </header>

    @if(session('toast'))<div class="buyer-home-flash" role="status">{{ session('toast') }}</div>@endif

    <div class="buyer-home-summary" aria-label="Order summary">
        <article><span>Orders placed</span><strong>{{ $totalOrderCount }}</strong></article>
        <article><span>In progress</span><strong>{{ $activeOrderCount }}</strong></article>
        @if(auth()->user()?->hasRole('buyer'))
            <a href="{{ route('buyer.addresses') }}"><span>Delivery details</span><strong>Manage addresses <span aria-hidden="true">→</span></strong></a>
            <a href="{{ route('buyer.wishlist') }}"><span>Saved items</span><strong>Wishlist &amp; followed stores <span aria-hidden="true">→</span></strong></a>
        @else
            <a href="{{ auth()->check() ? route('profile') : route('login') }}"><span>Account settings</span><strong>{{ auth()->check() ? 'View profile' : 'Sign in' }} <span aria-hidden="true">→</span></strong></a>
        @endif
    </div>

    <section class="buyer-orders-panel" aria-labelledby="buyer-orders-title">
        <div class="buyer-orders-heading">
            <div><span class="buyer-home-eyebrow">YOUR PURCHASES</span><h2 id="buyer-orders-title">Recent orders</h2></div>
            <span>{{ $totalOrderCount }} {{ Str::plural('order', $totalOrderCount) }}</span>
        </div>

        @forelse($orders as $order)
            <article class="buyer-order-row">
                <div class="buyer-order-main">
                    <div class="buyer-order-title"><strong>{{ $order->order_number }}</strong><span class="buyer-order-status status-{{ strtolower($order->status->value) }}">{{ str($order->status->value)->replace('_', ' ')->title() }}</span></div>
                    <p>{{ $order->placed_at?->format('M j, Y · g:i A') ?? 'Date unavailable' }} <span aria-hidden="true">·</span> {{ $order->items->sum('quantity') }} {{ Str::plural('item', $order->items->sum('quantity')) }} <span aria-hidden="true">·</span> Sold by {{ $order->seller?->name ?? 'JEAP seller' }}</p>
                    @if($order->parcel)<small>Tracking number <strong>{{ $order->parcel->tracking_number }}</strong></small>@endif
                </div>
                <div class="buyer-order-actions">
                    <strong>₱{{ number_format((float) $order->total, 2) }}</strong>
                    <a href="{{ route('buyer.orders.track', $order) }}">{{ $order->parcel ? 'Track order' : 'View order' }} <span aria-hidden="true">→</span></a>
                    @if(in_array($order->status, [\App\Enums\OrderStatus::Placed, \App\Enums\OrderStatus::Confirmed, \App\Enums\OrderStatus::Preparing], true))
                        <form method="post" action="{{ route('buyer.orders.cancel', $order) }}" class="buyer-cancel-form">
                            @csrf
                            <label for="cancel-reason-{{ $order->id }}">Cancel order</label>
                            <input id="cancel-reason-{{ $order->id }}" name="reason" minlength="10" maxlength="300" placeholder="Tell us why" required>
                            <button type="submit">Cancel</button>
                        </form>
                    @endif
                </div>
            </article>
        @empty
            <div class="buyer-orders-empty">
                <span aria-hidden="true">🛍</span>
                <h3>No orders yet</h3>
                <p>Your purchases and shipment updates will appear here.</p>
                <a href="{{ route('products.index') }}">Explore products</a>
            </div>
        @endforelse

        @if($orders->hasPages())<div class="buyer-orders-pagination">{{ $orders->links() }}</div>@endif
    </section>
</div>
@endsection
