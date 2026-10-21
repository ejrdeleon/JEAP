@extends('layouts.dashboard')
@section('title', $title)
@section('nav')
    <a href="{{ route('admin.dashboard') }}">Dashboard</a>
@endsection
@section('content')
    <h1>{{ $title }}</h1>
    <p>Figma frame: {{ $figma }}</p>
    <p>Shell only — logic lands in later slices.</p>
@endsection
