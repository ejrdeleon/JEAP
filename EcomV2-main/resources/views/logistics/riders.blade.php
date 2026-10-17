@extends('layouts.dashboard')
@section('title', 'Rider management')
@section('nav')
    <a href="{{ route('logistics.dashboard') }}">Shipments</a>
    <a href="{{ route('logistics.couriers') }}">Rider approvals</a>
    <a class="active" href="{{ route('logistics.riders') }}">Riders</a>
@endsection
@section('content')
<section class="admin-page">
    <header class="admin-heading"><div><span class="admin-eyebrow">{{ $company->hub_business_name }}</span><h1>Rider management</h1><p>Add riders to your company and manage their activation.</p></div></header>
    @if (session('status'))<p class="admin-notice" role="status">{{ session('status') }}</p>@endif
    @if ($errors->any())<p class="admin-error" role="alert">{{ $errors->first() }}</p>@endif

    <section class="admin-panel rider-create-panel">
        <h2>Add a rider</h2>
        <p>New riders receive an activation link that expires after 24 hours. Documents are stored privately.</p>
        <form method="post" action="{{ route('logistics.riders.store') }}" enctype="multipart/form-data" class="admin-form rider-create-form">
            @csrf
            <div class="rider-form-grid">
                <label class="admin-field"><span>First name</span><input name="first_name" value="{{ old('first_name') }}" minlength="2" maxlength="50" required></label>
                <label class="admin-field"><span>Last name</span><input name="last_name" value="{{ old('last_name') }}" minlength="2" maxlength="50" required></label>
                <label class="admin-field"><span>Date of birth</span><input type="date" name="birthday" value="{{ old('birthday') }}" max="{{ now()->subYears(18)->toDateString() }}" required></label>
                <label class="admin-field"><span>Email</span><input type="email" name="email" value="{{ old('email') }}" autocomplete="email" required></label>
                <label class="admin-field"><span>Mobile number</span><input type="tel" name="phone" value="{{ old('phone') }}" placeholder="09XX XXX XXXX" required></label>
                <label class="admin-field"><span>Driver’s license number</span><input name="license_number" value="{{ old('license_number') }}" placeholder="N01-23-456789" pattern="[A-Za-z][0-9]{2}-[0-9]{2}-[0-9]{6}" required></label>
                <label class="admin-field"><span>License expiry</span><input type="date" name="license_expires_at" value="{{ old('license_expires_at') }}" min="{{ now()->toDateString() }}" required></label>
                <label class="admin-field"><span>Vehicle type</span><select name="vehicle_type" required><option value="">Select vehicle</option>@foreach (['motorcycle' => 'Motorcycle', 'car' => 'Car', 'van' => 'Van'] as $value => $label)<option value="{{ $value }}" @selected(old('vehicle_type') === $value)>{{ $label }}</option>@endforeach</select></label>
                <label class="admin-field"><span>Plate number</span><input name="plate_number" value="{{ old('plate_number') }}" maxlength="16" required></label>
                <label class="admin-field"><span>Driver’s license file · JPG, PNG, PDF · max 5 MB</span><input type="file" name="documents[drivers_license]" accept=".jpg,.jpeg,.png,.pdf" required></label>
                <label class="admin-field"><span>Vehicle OR/CR · JPG, PNG, PDF · max 5 MB</span><input type="file" name="documents[vehicle_registration]" accept=".jpg,.jpeg,.png,.pdf" required></label>
            </div>
            <button class="admin-button" type="submit">Add rider and send activation link</button>
        </form>
    </section>

    <section class="admin-panel">
        <div class="admin-panel-heading"><div><h2>Your riders</h2><p>Only riders linked to your logistics company appear here.</p></div></div>
        @forelse ($riders as $rider)
            <article class="admin-record">
                <div class="admin-record-head"><div><h3>{{ $rider->name }}</h3><p>{{ $rider->email }} · {{ $rider->phone }}</p></div><span class="admin-pill">{{ $rider->status->label() }}</span></div>
                <p class="admin-meta">{{ ucfirst($rider->courierProfile->vehicle_type) }} · {{ $rider->courierProfile->plate_number }} · License expires {{ $rider->courierProfile->license_expires_at?->format('M j, Y') }}</p>
                @if ($rider->status === \App\Enums\UserStatus::PendingActivation)
                    <form method="post" action="{{ route('logistics.riders.resend', $rider) }}">@csrf<button class="admin-button admin-button-small" type="submit">Resend activation link</button></form>
                @endif
            </article>
        @empty
            <p class="admin-empty">No riders have been added yet.</p>
        @endforelse
        <div class="admin-pagination">{{ $riders->links() }}</div>
    </section>
</section>
@endsection
