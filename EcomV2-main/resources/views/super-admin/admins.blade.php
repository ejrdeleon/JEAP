@extends('layouts.dashboard')
@section('title', 'Administrator accounts')
@section('nav')
    @include('partials.super-admin-nav')
@endsection
@section('content')
    <section class="admin-page">
        <header class="admin-heading"><div><span class="admin-eyebrow">ACCESS CONTROL</span><h1>Administrator accounts</h1><p>Create admin access and suspend or reactivate existing administrators.</p></div></header>
        @if (session('status')) <p class="admin-notice">{{ session('status') }}</p> @endif
        @if ($errors->any()) <p class="admin-error">{{ $errors->first() }}</p> @endif
        <section class="admin-panel"><h2>Create administrator</h2>
            <form method="post" action="{{ route('super-admin.admins.store') }}" class="admin-form">
                @csrf
                <div class="admin-form-grid">
                    <label class="admin-field"><span>First name</span><input name="first_name" maxlength="255" required value="{{ old('first_name') }}"></label>
                    <label class="admin-field"><span>Last name</span><input name="last_name" maxlength="255" required value="{{ old('last_name') }}"></label>
                    <label class="admin-field"><span>Email</span><input type="email" name="email" maxlength="255" required value="{{ old('email') }}"></label>
                    <label class="admin-field"><span>Phone (optional)</span><input type="tel" name="phone" maxlength="32" value="{{ old('phone') }}"></label>
                    <label class="admin-field"><span>Temporary password</span><input type="password" name="password" minlength="12" required autocomplete="new-password"></label>
                    <label class="admin-field"><span>Confirm password</span><input type="password" name="password_confirmation" minlength="12" required autocomplete="new-password"></label>
                </div>
                <p class="admin-help">Use a unique password with at least 12 characters. The account is activated immediately.</p>
                <button class="admin-button">Create administrator</button>
            </form>
        </section>
        <section class="admin-panel"><h2>Current administrators</h2>
            <div class="admin-table-wrap"><table class="admin-table"><thead><tr><th>Administrator</th><th>Email</th><th>Role</th><th>Status</th><th>Access control</th></tr></thead>
                <tbody>@forelse ($admins as $admin)<tr>
                    <td><strong>{{ $admin->name }}</strong><small>Joined {{ $admin->created_at->format('M j, Y') }}</small></td>
                    <td>{{ $admin->email }}</td><td>{{ $admin->roles->pluck('name')->join(', ') }}</td>
                    <td><span class="admin-pill">{{ $admin->status->label() }}</span></td>
                    <td>@if ($admin->id === auth()->id())<span class="admin-help">Your account</span>@else
                        <form method="post" action="{{ route('super-admin.admins.status', $admin) }}" class="admin-inline-form">
                            @csrf @method('PATCH')
                            <select name="status" aria-label="New status for {{ $admin->name }}"><option value="active">Active</option><option value="suspended">Suspended</option><option value="deactivated">Deactivated</option></select>
                            <button class="admin-button admin-button-small">Save</button>
                        </form>
                    @endif</td>
                </tr>@empty<tr><td colspan="5" class="admin-empty">No admin accounts found.</td></tr>@endforelse</tbody>
            </table></div>
            <div class="admin-pagination">{{ $admins->links() }}</div>
        </section>
    </section>
@endsection
