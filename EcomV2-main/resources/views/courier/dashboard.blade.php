@extends('layouts.dashboard')
@section('title', 'Rider dashboard')
@section('nav')
    <a class="active" href="{{ route('courier.dashboard') }}">Rider dashboard</a>
@endsection
@section('content')
<div class="rider-dashboard" data-figma="11_Driver_Courier_Dashboard 1">
    <header class="rider-dashboard-heading">
        <div><span class="buyer-home-eyebrow">JEAP RIDER</span><h1>Hello, {{ auth()->user()->first_name }}</h1><p>Manage your availability and today’s delivery work.</p></div>
        <form method="post" action="{{ route('courier.availability') }}" class="rider-availability-form">@csrf @method('PATCH')<input type="hidden" name="is_online" value="{{ $rider->is_online ? 0 : 1 }}"><button class="{{ $rider->is_online ? 'is-online' : '' }}" type="submit">{{ $rider->is_online ? '● Online · Go offline' : '○ Offline · Go online' }}</button></form>
    </header>
    @if(session('status'))<div class="buyer-home-flash" role="status">{{ session('status') }}</div>@endif
    @if($errors->any())<div class="buyer-home-flash rider-error" role="alert">{{ $errors->first() }}</div>@endif
    <div class="rider-summary"><article><span>Availability</span><strong>{{ $rider->is_online ? 'Online' : 'Offline' }}</strong></article><article><span>Completed today</span><strong>{{ $completedDeliveryCount }}</strong></article><article><span>Assigned area</span><strong>{{ $rider->area?->name ?? 'Not assigned' }}</strong></article></div>

    <section class="rider-panel"><div class="rider-panel-heading"><div><span class="buyer-home-eyebrow">PICKUP WORK</span><h2>Pickup assignments</h2></div><span>{{ $pickupAssignments->count() }} active</span></div>
        @forelse($pickupAssignments as $assignment)
            <article class="rider-job" data-rider-job>
                <div class="rider-job-heading"><strong>{{ $assignment->parcel->tracking_number }}</strong><span>{{ str($assignment->status)->replace('_', ' ')->title() }}</span></div>
                <p>Order {{ $assignment->parcel->order->order_number }} · Pickup from {{ $assignment->seller?->name ?? 'seller' }}</p>
                <ul>@foreach($assignment->parcel->order->items as $item)<li>{{ $item->quantity }} × {{ $item->name }}</li>@endforeach</ul>
                <div class="rider-job-actions">
                    @if($assignment->status === 'pending')<button type="button" data-rider-action="pickup-{{ $assignment->id }}" data-action="accept">Accept assignment</button>@endif
                    @if($assignment->status === 'accepted')<button type="button" data-rider-action="pickup-{{ $assignment->id }}" data-action="scan">Confirm pickup</button>@endif
                </div>
            </article>
        @empty<p class="rider-empty">No pickup jobs are assigned right now.</p>@endforelse
    </section>

    <section class="rider-panel"><div class="rider-panel-heading"><div><span class="buyer-home-eyebrow">LAST MILE</span><h2>Delivery assignments</h2></div><span>{{ $deliveryAssignments->whereIn('status', ['pending', 'accepted', 'out_for_delivery'])->count() }} active</span></div>
        @forelse($deliveryAssignments as $assignment)
            <article class="rider-job" data-rider-job>
                <div class="rider-job-heading"><strong>{{ $assignment->parcel->tracking_number }}</strong><span>{{ str($assignment->status)->replace('_', ' ')->title() }}</span></div>
                <p>Order {{ $assignment->parcel->order->order_number }} · {{ $assignment->parcel->order->buyer?->name }}</p>
                <p class="rider-job-address">{{ collect($assignment->parcel->order->shipping_address_snapshot ?? [])->only(['street_line', 'barangay_name', 'city_name', 'province_name'])->filter()->implode(', ') }}</p>
                <ul>@foreach($assignment->parcel->order->items as $item)<li>{{ $item->quantity }} × {{ $item->name }}</li>@endforeach</ul>
                <div class="rider-job-actions">
                    @if($assignment->status === 'pending')<button type="button" data-rider-action="delivery-{{ $assignment->id }}" data-action="accept">Accept assignment</button>@endif
                    @if($assignment->status === 'accepted')<button type="button" data-rider-action="delivery-{{ $assignment->id }}" data-action="out-for-delivery">Start delivery</button>@endif
                    @if($assignment->status === 'out_for_delivery')
                        <form data-rider-form data-assignment="delivery-{{ $assignment->id }}" data-action="deliver" enctype="multipart/form-data"><label>Proof of delivery <input type="file" name="proof" accept="image/jpeg,image/png,image/webp" required></label><button type="submit">Confirm delivered</button></form>
                        <form data-rider-form data-assignment="delivery-{{ $assignment->id }}" data-action="fail"><label>Failed delivery reason <input name="reason" minlength="3" maxlength="255" placeholder="Recipient unavailable" required></label><button type="submit" class="is-secondary">Record failed attempt</button></form>
                    @endif
                </div>
            </article>
        @empty<p class="rider-empty">No delivery jobs are assigned right now.</p>@endforelse
    </section>

    <details class="rider-panel rider-profile-panel"><summary><strong>Profile and vehicle details</strong><span>Update contact and vehicle information</span></summary>
        <form method="post" action="{{ route('courier.profile.update') }}" class="rider-profile-form">@csrf @method('PUT')
            <label>Phone number<input name="phone" value="{{ old('phone', auth()->user()->phone) }}" autocomplete="tel" required></label>
            <label>Vehicle type<select name="vehicle_type" required>@foreach(['motorcycle' => 'Motorcycle', 'car' => 'Car', 'van' => 'Van', 'truck' => 'Truck'] as $value => $label)<option value="{{ $value }}" @selected(old('vehicle_type', $rider->vehicle_type) === $value)>{{ $label }}</option>@endforeach</select></label>
            <label>Plate number<input name="plate_number" value="{{ old('plate_number', $rider->plate_number) }}" maxlength="20" required></label>
            <label>Driver’s license number<input name="license_number" value="{{ old('license_number', $rider->license_number) }}" maxlength="16" required></label>
            <label>License expiry<input type="date" name="license_expires_at" value="{{ old('license_expires_at', $rider->license_expires_at?->format('Y-m-d')) }}" min="{{ now()->addDay()->toDateString() }}" required></label>
            <button type="submit">Save rider profile</button>
        </form>
    </details>
</div>
@endsection
