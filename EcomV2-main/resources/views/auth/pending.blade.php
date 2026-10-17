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
    <p>Shoppers, sellers, and sorting centers are reviewed by Admin. Riders are reviewed by the sorting center.</p>
    <p><a href="{{ route('home') }}">Back to store</a></p>
</section>
@endsection
