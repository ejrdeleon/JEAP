@extends('layouts.storefront')

@section('title', 'Account information | JEAP')
@section('crumb')
    <span>My account</span><span>/</span><span>Account information</span>
@endsection

@section('content')
<div class="account-page">
    <header class="account-page-heading">
        <div><span class="account-eyebrow">MY JEAP ACCOUNT</span><h1>Account information</h1><p>Manage your profile and find your orders and delivery details.</p></div>
    </header>

    <div class="account-page-layout">
        <aside class="account-side-card" aria-label="Account navigation">
            <div class="account-avatar" aria-hidden="{{ $user->avatarUrl() ? 'false' : 'true' }}">
                @if($user->avatarUrl())
                    <img src="{{ $user->avatarUrl() }}" alt="{{ $user->name }}">
                @else
                    {{ mb_strtoupper(mb_substr($user->first_name ?: $user->email, 0, 1)) }}
                @endif
            </div>
            <strong>{{ $user->name }}</strong>
            <a class="account-email" href="mailto:{{ $user->email }}">{{ $user->email }}</a>
            <nav class="account-links">
                <a class="is-current" href="{{ route('profile') }}" aria-current="page">Account information</a>
                <a href="{{ route('buyer.home') }}">My orders</a>
                @if($user->hasRole('buyer'))<a href="{{ route('buyer.addresses') }}">Delivery addresses</a>@endif
            </nav>
            <x-logout-form button-class="account-logout">Sign out</x-logout-form>
        </aside>

        <section class="account-form-card" aria-labelledby="account-form-title">
            @if ($errors->any())<div class="account-message is-error" role="alert">{{ $errors->first() }}</div>@endif
            @if (session('toast'))<div class="account-message is-success" role="status">{{ session('toast') }}</div>@endif
            <div class="account-form-heading"><div><span class="account-eyebrow">PERSONAL DETAILS</span><h2 id="account-form-title">Your profile</h2></div><span class="account-status status-{{ str($user->status->value)->slug('_') }}">{{ str($user->status->value)->replace('_', ' ')->title() }}</span></div>
            <form method="post" action="{{ route('profile.update') }}" enctype="multipart/form-data">
                @csrf
                <div class="account-field-grid">
                    <div class="account-field account-field-wide"><label for="profile-avatar">Profile photo</label><input id="profile-avatar" type="file" name="avatar" accept="image/jpeg,image/png,image/webp">@error('avatar')<small>{{ $message }}</small>@enderror</div>
                    <div class="account-field"><label for="profile-first-name">First name</label><input id="profile-first-name" name="first_name" value="{{ old('first_name', $user->first_name) }}" autocomplete="given-name" required @error('first_name') aria-invalid="true" @enderror>@error('first_name')<small>{{ $message }}</small>@enderror</div>
                    <div class="account-field"><label for="profile-last-name">Last name</label><input id="profile-last-name" name="last_name" value="{{ old('last_name', $user->last_name) }}" autocomplete="family-name" required @error('last_name') aria-invalid="true" @enderror>@error('last_name')<small>{{ $message }}</small>@enderror</div>
                    <div class="account-field"><label for="profile-email">Email address</label><input id="profile-email" type="email" name="email" value="{{ old('email', $user->email) }}" autocomplete="email" required @error('email') aria-invalid="true" @enderror>@error('email')<small>{{ $message }}</small>@enderror</div>
                    <div class="account-field"><label for="profile-phone">Phone number <span>Optional</span></label><input id="profile-phone" type="tel" name="phone" value="{{ old('phone', $user->phone) }}" autocomplete="tel" @error('phone') aria-invalid="true" @enderror>@error('phone')<small>{{ $message }}</small>@enderror</div>
                </div>
                <div class="account-form-footer"><p>Account type: {{ $user->roles->pluck('name')->map(fn ($role) => str($role)->replace('-', ' ')->title())->join(', ') ?: 'Member' }}</p><button type="submit">Save changes</button></div>
            </form>
        </section>
    </div>
</div>
@endsection
