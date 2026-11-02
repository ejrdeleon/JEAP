@extends('layouts.storefront')

@section('title', 'Session expired')
@section('content')
<section class="s3-main" style="padding:64px 30px;">
    <h2>Your session expired</h2>
    <p>JEAP needs a fresh page so the form can be submitted safely. Reload and try again.</p>
    <p><a class="s3-btn" href="{{ url()->previous() }}">Go back</a> <a class="s3-link" href="{{ route('login') }}">Log in</a></p>
</section>
@endsection
