@extends('layouts.storefront')

@section('title', 'Page expired')
@section('crumb')
    <span>Page expired</span>
@endsection

@section('content')
<section class="status-screen">
    <div class="status-card">
        <p class="status-kicker">Session</p>
        <h1>This page expired</h1>
        <p>Reload and try again. JEAP does this to keep forms like checkout and sign-in safe.</p>
        <div class="status-actions">
            <a class="status-btn status-btn--primary" href="{{ url()->current() }}">Reload</a>
            <a class="status-btn status-btn--ghost" href="{{ route('home') }}">Go to home</a>
            <a class="status-link" href="{{ route('login') }}">Log in</a>
        </div>
    </div>
</section>
@endsection
