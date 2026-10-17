@extends('layouts.storefront')

@section('title', 'Pending approval')
@section('crumb')
    <a href="{{ route('register') }}">pages</a>
    <span>/</span>
    <span>pending</span>
@endsection

@section('content')
<section class="s3-main" style="padding:80px 30px;">
    <h1>Pending approval</h1>
    <p>{{ session('status') ?? 'Your account cannot sign in until it is approved.' }}</p>
    <p>Seller and logistics applications are reviewed by an admin. Rider accounts are created by an approved logistics company.</p>
    <p><a href="{{ route('home') }}">Back to store</a></p>
</section>
@endsection
