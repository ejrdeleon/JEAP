@extends('layouts.dashboard')
@section('title', 'Super Admin')
@section('nav')
    <a class="active" href="{{ route('super-admin.dashboard') }}">Overview</a>
    <a href="{{ route('super-admin.admins') }}">Administrator accounts</a>
    <a href="{{ route('super-admin.settings') }}">Platform settings</a>
    <a href="{{ route('admin.dashboard') }}">Admin workspace</a>
@endsection
@section('content')
    <section class="admin-page">
        <header class="admin-heading"><div><span class="admin-eyebrow">PLATFORM CONTROL</span><h1>Super admin</h1><p>Manage administrator access and platform-wide settings.</p></div><a class="admin-button" href="{{ route('super-admin.admins') }}">Manage admins</a></header>
        <div class="admin-stats">
            <article><span>Administrator accounts</span><strong>{{ number_format($adminCount) }}</strong><a href="{{ route('super-admin.admins') }}">View accounts</a></article>
            <article><span>Active administrators</span><strong>{{ number_format($activeAdmins) }}</strong><a href="{{ route('super-admin.admins') }}">Manage access</a></article>
            <article><span>Platform policies</span><strong>{{ number_format($policyCount) }}</strong><a href="{{ route('super-admin.settings') }}">Edit settings</a></article>
            <article><span>Published announcements</span><strong>{{ number_format($publishedAnnouncements) }}</strong><a href="{{ route('admin.cms') }}">Manage CMS</a></article>
        </div>
        <section class="admin-panel"><div class="admin-panel-heading"><div><h2>Administrator accounts</h2><p>Most recently created administrator accounts</p></div><a href="{{ route('super-admin.admins') }}">View all</a></div>
            <div class="admin-table-wrap"><table class="admin-table"><thead><tr><th>Administrator</th><th>Email</th><th>Status</th><th>Added</th></tr></thead>
                <tbody>@forelse ($recentAdmins as $admin)<tr><td>{{ $admin->name }}</td><td>{{ $admin->email }}</td><td><span class="admin-pill">{{ $admin->status->label() }}</span></td><td>{{ $admin->created_at->format('M j, Y') }}</td></tr>@empty<tr><td colspan="4" class="admin-empty">No administrator accounts yet.</td></tr>@endforelse</tbody>
            </table></div>
        </section>
    </section>
@endsection
