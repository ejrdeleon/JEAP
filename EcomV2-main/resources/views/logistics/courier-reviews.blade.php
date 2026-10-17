@extends('layouts.dashboard')
@section('title', 'Courier approvals')
@section('nav')
    <a href="{{ route('logistics.dashboard') }}">Warehouse</a>
    <a class="active" href="{{ route('logistics.couriers') }}">Courier approvals</a>
@endsection
@section('content')
    <h1>Courier approval queue</h1>
    @if (session('status')) <p>{{ session('status') }}</p> @endif
    @forelse ($users as $user)
        <div style="background:#fff;padding:16px;margin-bottom:12px;">
            <strong>{{ $user->name }}</strong> · {{ $user->email }}
            <div>{{ $user->courierProfile?->vehicle_type }} {{ $user->courierProfile?->plate_number }}</div>
            <form method="post" action="{{ route('logistics.couriers.decide', $user) }}">
                @csrf
                <button name="decision" value="approved">Approve</button>
                <button name="decision" value="rejected">Reject</button>
            </form>
        </div>
    @empty
        <p>No pending couriers.</p>
    @endforelse
@endsection
