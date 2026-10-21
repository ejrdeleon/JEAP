<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>@yield('title') — JEAP</title>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
</head>
<body class="dash">
    <aside class="dash-side">
        <a class="dash-brand" href="{{ route('home') }}">
            <img src="{{ asset('images/storefront/logo.svg') }}" alt="JEAP" width="88" height="32">
        </a>
        <nav>
            @yield('nav')
            <a href="{{ route('home') }}">Storefront</a>
            <x-logout-form style="margin-top:16px;" />
        </nav>
    </aside>
    <main class="dash-main">
        @yield('content')
    </main>
</body>
</html>
