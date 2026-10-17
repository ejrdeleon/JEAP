@extends('layouts.dashboard')
@section('title', $title)
@section('nav')
    <a href="{{ route('seller.dashboard') }}">seller_center</a>
@endsection
@section('content')
    <h1>{{ $title }}</h1>
    <p>Figma frame: {{ $figma }}</p>
@endsection
