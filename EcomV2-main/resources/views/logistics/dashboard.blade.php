@extends('layouts.dashboard')
@section('title', 'Warehouse')
@section('nav')
    <a class="active" href="{{ route('logistics.dashboard') }}">12_Warehouse_Management 1</a>
    <a href="{{ route('logistics.couriers') }}">Courier approvals</a>
@endsection
@section('content')
    <h1>12_Warehouse_Management 1</h1>
    <p>Scan, sort by area, assign rider.</p>
@endsection
