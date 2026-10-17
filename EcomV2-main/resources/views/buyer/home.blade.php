@extends('layouts.storefront')
@section('title', '01_Buyer_Home 1')
@section('content')
<section class="storefront-pad" data-figma="01_Buyer_Home 1" style="padding-block:40px;">
    <h1>01_Buyer_Home 1</h1>
    <p>Welcome {{ auth()->user()?->first_name }}.</p>
    <p><a href="{{ route('buyer.addresses') }}">02_Auth_Address 1</a> · <a href="{{ route('search') }}">03_Search_Filters 1</a> · <a href="{{ route('buyer.cart') }}">04_MultiSeller_Cart 1</a></p>
</section>
@endsection
