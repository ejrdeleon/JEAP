@extends('layouts.dashboard')
@section('title', 'Admin 1')
@section('nav')
    <a href="{{ route('admin.dashboard') }}">Overview</a>
    <a class="active" href="{{ route('admin.verifications') }}">Verifications</a>
    <a href="{{ route('admin.cms') }}">Marketplace CMS</a>
    <a href="{{ route('admin.users') }}">Users</a>
    <a href="{{ route('admin.disputes') }}">Disputes</a>
    <a href="{{ route('admin.reports') }}">Reports</a>
    @if (auth()->user()->hasRole('super-admin')) <a href="{{ route('super-admin.dashboard') }}">Super admin</a> @endif
@endsection
@section('content')
    <section class="admin-page">
        <header class="admin-heading"><div><span class="admin-eyebrow">ACCOUNT REVIEW</span><h1>Verification queue</h1><p>Approve or reject new marketplace registrations.</p></div></header>
        @if (session('status')) <p class="admin-notice">{{ session('status') }}</p> @endif
        @if ($errors->any()) <p class="admin-error">{{ $errors->first() }}</p> @endif
        <section class="admin-panel">
            @forelse ($users as $user)
                <article class="admin-record">
                    <div class="admin-record-head"><div><h2>{{ $user->name }}</h2><p>{{ $user->email }} · {{ $user->roles->pluck('name')->join(', ') }}</p></div><span class="admin-pill">Pending</span></div>
                    @if ($user->sellerProfile) <p>Business: {{ $user->sellerProfile->business_name }}</p> @endif
                    @if ($user->logisticsProfile) <p>Hub: {{ $user->logisticsProfile->hub_business_name }}</p> @endif
                    @if ($user->kycDocuments->isNotEmpty())
                        <div class="admin-docs"><strong>KYC documents</strong>
                            @foreach ($user->kycDocuments as $document)
                                <span>{{ $document->type }} · {{ $document->review_status }}</span>
                            @endforeach
                        </div>
                    @endif
                    <form method="post" action="{{ route('admin.verifications.decide', $user) }}" class="admin-form admin-review-form">
                        @csrf
                        <label class="admin-field"><span>Review notes</span><textarea name="notes" maxlength="2000" rows="2">{{ old('notes') }}</textarea></label>
                        <div class="admin-actions"><button class="admin-button" name="decision" value="approved">Approve account</button><button class="admin-button admin-button-danger" name="decision" value="rejected">Reject</button></div>
                    </form>
                </article>
            @empty
                <p class="admin-empty">No registrations are waiting for review.</p>
            @endforelse
        </section>
    </section>
@endsection
