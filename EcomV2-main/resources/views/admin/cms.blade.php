@extends('layouts.dashboard')
@section('title', 'Marketplace CMS')
@section('nav')
    <a href="{{ route('admin.dashboard') }}">Overview</a>
    <a href="{{ route('admin.verifications') }}">Verifications</a>
    <a class="active" href="{{ route('admin.cms') }}">Marketplace CMS</a>
    <a href="{{ route('admin.users') }}">Users</a>
    <a href="{{ route('admin.disputes') }}">Disputes</a>
    <a href="{{ route('admin.reports') }}">Reports</a>
    @if (auth()->user()->hasRole('super-admin')) <a href="{{ route('super-admin.dashboard') }}">Super admin</a> @endif
@endsection
@section('content')
    <section class="admin-page">
        <header class="admin-heading"><div><span class="admin-eyebrow">CONTENT MANAGEMENT</span><h1>Marketplace CMS</h1><p>Publish announcements to marketplace users.</p></div></header>
        @if (session('status')) <p class="admin-notice">{{ session('status') }}</p> @endif
        @if ($errors->any()) <p class="admin-error">{{ $errors->first() }}</p> @endif
        <section class="admin-panel">
            <h2>Create announcement</h2>
            <form method="post" action="{{ route('admin.cms.store') }}" class="admin-form">
                @csrf
                <div class="admin-form-grid">
                    <label class="admin-field"><span>Title</span><input name="title" maxlength="255" required value="{{ old('title') }}"></label>
                    <label class="admin-field"><span>Audience</span><select name="audience" required><option value="all">Everyone</option><option value="buyers">Buyers</option><option value="sellers">Sellers</option></select></label>
                </div>
                <label class="admin-field"><span>Announcement</span><textarea name="body" rows="4" maxlength="10000" required>{{ old('body') }}</textarea></label>
                <label class="admin-check"><input type="checkbox" name="is_published" value="1"> Publish immediately</label>
                <button class="admin-button">Create announcement</button>
            </form>
        </section>
        <section class="admin-panel">
            <div class="admin-panel-heading"><div><h2>Announcements</h2><p>Update or change the publication status of existing posts.</p></div></div>
            @forelse ($announcements as $announcement)
                <article class="admin-record">
                    <div class="admin-record-head"><div><h3>{{ $announcement->title }}</h3><p>{{ ucfirst($announcement->audience) }} · Created {{ $announcement->created_at->format('M j, Y') }}</p></div><span class="admin-pill">{{ $announcement->is_published ? 'Published' : 'Draft' }}</span></div>
                    <form method="post" action="{{ route('admin.cms.update', $announcement) }}" class="admin-form">
                        @csrf @method('PUT')
                        <div class="admin-form-grid">
                            <label class="admin-field"><span>Title</span><input name="title" maxlength="255" required value="{{ $announcement->title }}"></label>
                            <label class="admin-field"><span>Audience</span><select name="audience"><option value="all" @selected($announcement->audience === 'all')>Everyone</option><option value="buyers" @selected($announcement->audience === 'buyers')>Buyers</option><option value="sellers" @selected($announcement->audience === 'sellers')>Sellers</option></select></label>
                        </div>
                        <label class="admin-field"><span>Announcement</span><textarea name="body" rows="3" maxlength="10000" required>{{ $announcement->body }}</textarea></label>
                        <label class="admin-check"><input type="checkbox" name="is_published" value="1" @checked($announcement->is_published)> Published</label>
                        <button class="admin-button admin-button-secondary">Save changes</button>
                    </form>
                    <form method="post" action="{{ route('admin.cms.publish', $announcement) }}" class="admin-publish-form">
                        @csrf @method('PATCH')
                        <button class="admin-button admin-button-small">{{ $announcement->is_published ? 'Unpublish' : 'Publish' }}</button>
                    </form>
                </article>
            @empty<p class="admin-empty">No announcements have been created.</p>@endforelse
            <div class="admin-pagination">{{ $announcements->links() }}</div>
        </section>
    </section>
@endsection
