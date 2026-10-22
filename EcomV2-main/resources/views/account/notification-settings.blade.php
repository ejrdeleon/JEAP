@extends('layouts.storefront')

@section('title', 'Notification settings | JEAP')
@section('crumb')
    <span>My account</span><span>/</span><span>Notification settings</span>
@endsection

@section('content')
<div class="account-page">
    <header class="account-page-heading"><div><span class="account-eyebrow">MY JEAP ACCOUNT</span><h1>Notification settings</h1><p>Choose what appears in your JEAP inbox.</p></div></header>
    <div class="account-page-layout">
        <aside class="account-side-card">
            <strong>{{ $user->name }}</strong>
            @include('partials.account-nav', ['user' => $user])
        </aside>
        <section class="account-form-card">
            @if (session('toast'))<div class="account-message is-success" role="status">{{ session('toast') }}</div>@endif
            <form method="post" action="{{ route('account.notification-settings.update') }}">
                @csrf
                <label class="register-terms"><input type="checkbox" name="order_updates" value="1" @checked($preferences['order_updates'])> Order updates</label>
                <label class="register-terms"><input type="checkbox" name="chat" value="1" @checked($preferences['chat'])> Chat messages</label>
                <label class="register-terms"><input type="checkbox" name="promos" value="1" @checked($preferences['promos'])> Shop vouchers and promos</label>
                <div class="account-form-footer"><p>These alerts stay on JEAP. Email is only used for verification codes.</p><button type="submit">Save preferences</button></div>
            </form>
        </section>
    </div>
</div>
@endsection
