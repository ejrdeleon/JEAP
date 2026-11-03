@extends('layouts.storefront')

@section('title', auth()->check() ? 'Sign out' : 'Signed out')
@section('crumb')
    <span>{{ auth()->check() ? 'Sign out' : 'Signed out' }}</span>
@endsection

@section('content')
<section class="status-screen">
    <div class="status-card">
        @auth
            <p class="status-kicker">Account</p>
            <h1>Sign out of JEAP?</h1>
            <p>You will need to log in again for orders, chat, and checkout. You can keep shopping as a guest.</p>
            <div class="status-actions">
                <form method="post" action="{{ route('logout') }}">
                    @csrf
                    <button class="status-btn status-btn--primary" type="submit">Sign out</button>
                </form>
                <a class="status-btn status-btn--ghost" href="{{ url()->previous() !== url()->current() ? url()->previous() : route('home') }}">Stay signed in</a>
            </div>
        @else
            <p class="status-kicker">Account</p>
            <h1>You're signed out</h1>
            <p>Shop as a guest, or log in when you want Cash on Delivery, saved addresses, and order tracking.</p>
            <div class="status-actions">
                <a class="status-btn status-btn--primary" href="{{ route('home') }}">Continue shopping</a>
                <a class="status-btn status-btn--ghost" href="{{ route('login') }}">Log in</a>
                <a class="status-link" href="{{ route('register') }}">Sign up</a>
            </div>
        @endauth
    </div>
</section>
@endsection
