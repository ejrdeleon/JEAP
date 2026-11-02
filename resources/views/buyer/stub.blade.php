@extends('layouts.storefront')
@section('title', $title)
@section('content')
<section class="storefront-pad" data-figma="{{ $figma }}" style="padding-block:40px;">
    <h1>{{ $title }}</h1>
    <p>Figma frame: {{ $figma }}</p>
</section>
@endsection
