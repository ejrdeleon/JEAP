@extends('layouts.storefront')

@section('title', 'Profile')
@section('crumb')
    <a href="{{ route('about') }}">pages</a>
    <span>/</span>
    <span>profile</span>
@endsection

@section('content')
<section class="s3-main s3-profile" data-figma="Profile 7:492">
    <aside class="s3-tabs">
        <img src="{{ asset('images/storefront/avatar.svg') }}" alt="">
        <h5 style="margin:24px 0 8px;">{{ $user->name }}</h5>
        <p><a href="mailto:{{ $user->email }}">{{ $user->email }}</a></p>
        <a class="s3-tab is-on" href="{{ route('profile') }}">Account info →</a>
        <a class="s3-tab" href="{{ route('buyer.home') }}">My order →</a>
        <a class="s3-tab" href="{{ route('buyer.addresses') }}">My address →</a>
        <a class="s3-tab" href="{{ route('profile') }}">Change password →</a>
        <x-logout-form button-class="s3-btn" style="margin-top:16px;">log out</x-logout-form>
    </aside>
    <div>
        <h4 style="margin:0 0 24px;font-size:22px;">Account info</h4>
        @if ($errors->any())
            <p class="err">{{ $errors->first() }}</p>
        @endif
        @if (session('toast'))
            <p>{{ session('toast') }}</p>
        @endif
        <form method="post" action="/profile">
            @csrf
            <div class="s3-two">
                <div class="s3-field">
                    <label>First Name</label>
                    <input name="first_name" value="{{ old('first_name', $user->first_name) }}" required>
                </div>
                <div class="s3-field">
                    <label>Last Name</label>
                    <input name="last_name" value="{{ old('last_name', $user->last_name) }}" required>
                </div>
            </div>
            <div class="s3-field">
                <label>Email Address</label>
                <input type="email" name="email" value="{{ old('email', $user->email) }}" required>
            </div>
            <div class="s3-field">
                <label>Phone Number (optional)</label>
                <input name="phone" value="{{ old('phone', $user->phone) }}">
            </div>
            <p>Status: {{ $user->status->value }} · Role: {{ $user->roles->pluck('name')->join(', ') }}</p>
            <button class="s3-btn" type="submit" style="min-width:126px;">save</button>
        </form>
    </div>
</section>
@endsection
