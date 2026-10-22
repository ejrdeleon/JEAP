@extends('layouts.storefront')

@section('title', 'Change password | JEAP')
@section('crumb')
    <span>My account</span><span>/</span><span>Change password</span>
@endsection

@section('content')
<div class="account-page">
    <header class="account-page-heading"><div><span class="account-eyebrow">MY JEAP ACCOUNT</span><h1>Change password</h1><p>Use a password only you know. It must be at least 8 characters with mixed case and a number.</p></div></header>
    <div class="account-page-layout">
        <aside class="account-side-card">
            <strong>{{ $user->name }}</strong>
            @include('partials.account-nav', ['user' => $user])
        </aside>
        <section class="account-form-card">
            @if ($errors->any())<div class="account-message is-error" role="alert">{{ $errors->first() }}</div>@endif
            @if (session('toast'))<div class="account-message is-success" role="status">{{ session('toast') }}</div>@endif
            <form method="post" action="{{ route('account.password.update') }}">
                @csrf
                <div class="account-field-grid">
                    <div class="account-field account-field-wide"><label for="current-password">Current password</label><input id="current-password" type="password" name="current_password" autocomplete="current-password" required></div>
                    <div class="account-field"><label for="new-password">New password</label><input id="new-password" type="password" name="password" autocomplete="new-password" required></div>
                    <div class="account-field"><label for="new-password-confirm">Confirm new password</label><input id="new-password-confirm" type="password" name="password_confirmation" autocomplete="new-password" required></div>
                </div>
                <div class="account-form-footer"><p>You’ll stay signed in on this device after the change.</p><button type="submit">Update password</button></div>
            </form>
        </section>
    </div>
</div>
@endsection
