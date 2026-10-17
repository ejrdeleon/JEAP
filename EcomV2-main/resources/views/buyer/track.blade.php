@extends('layouts.storefront')
@section('title', '06_Order_Tracking_Chat 1')
@section('content')
<section class="storefront-pad" data-figma="06_Order_Tracking_Chat 1" style="padding-block:40px;">
    <h1>06_Order_Tracking_Chat 1</h1>
    <p>Order {{ $order->order_number }} · {{ $order->status->value }}</p>
</section>
@endsection
