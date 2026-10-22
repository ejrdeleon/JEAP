@extends('layouts.dashboard')
@section('title', 'Users')
@section('nav')
    <a href="{{ route('admin.dashboard') }}">Overview</a>
    <a href="{{ route('admin.verifications') }}">Verifications</a>
    <a href="{{ route('admin.cms') }}">Marketplace CMS</a>
    <a class="active" href="{{ route('admin.users') }}">Users</a>
    <a href="{{ route('admin.disputes') }}">Disputes</a>
    <a href="{{ route('admin.reports') }}">Reports</a>
    @if (auth()->user()->hasRole('super-admin')) <a href="{{ route('super-admin.dashboard') }}">Super admin</a> @endif
@endsection
@section('content')
    <section class="admin-page">
        <header class="admin-heading"><div><span class="admin-eyebrow">MARKETPLACE ACCOUNTS</span><h1>Users</h1><p>Match profile photos when reviewing accounts. Give a reason whenever you suspend or deactivate someone.</p></div></header>
        @if (session('status')) <p class="admin-notice">{{ session('status') }}</p> @endif
        @if ($errors->any()) <p class="admin-error">{{ $errors->first() }}</p> @endif
        <section class="admin-panel">
            <form method="get" action="{{ route('admin.users') }}" class="admin-toolbar">
                <label class="admin-field"><span>Search</span><input type="search" name="q" value="{{ request('q') }}" placeholder="Name or email"></label>
                <label class="admin-field"><span>Account status</span><select name="status"><option value="">All statuses</option>@foreach ($statuses as $status)<option value="{{ $status->value }}" @selected(request('status') === $status->value)>{{ $status->label() }}</option>@endforeach</select></label>
                <button class="admin-button">Filter users</button>
            </form>
            <div class="admin-table-wrap"><table class="admin-table">
                <thead><tr><th>User</th><th>Role</th><th>Status</th><th>Joined</th><th>Update access</th></tr></thead>
                <tbody>@forelse ($users as $user)
                    <tr>
                        <td>@include('partials.admin-user-photo', ['user' => $user])</td>
                        <td>{{ $user->roles->pluck('name')->join(', ') ?: '—' }}</td>
                        <td><span class="admin-pill">{{ $user->status->label() }}</span></td>
                        <td>{{ $user->created_at->format('M j, Y') }}</td>
                        <td>@include('partials.account-access-form', ['account' => $user, 'action' => route('admin.users.status', $user)])</td>
                    </tr>
                @empty<tr><td colspan="5" class="admin-empty">No marketplace users match these filters.</td></tr>@endforelse</tbody>
            </table></div>
            <div class="admin-pagination">{{ $users->links() }}</div>
        </section>
    </section>
@endsection
