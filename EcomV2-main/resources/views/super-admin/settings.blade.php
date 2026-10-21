@extends('layouts.dashboard')
@section('title', 'Platform settings')
@section('nav')
    @include('partials.super-admin-nav')
@endsection
@section('content')
    <section class="admin-page">
        <header class="admin-heading"><div><span class="admin-eyebrow">PLATFORM CONTROL</span><h1>Platform settings</h1><p>Maintain policy content used across the marketplace.</p></div></header>
        @if (session('status')) <p class="admin-notice">{{ session('status') }}</p> @endif
        @if ($errors->any()) <p class="admin-error">{{ $errors->first() }}</p> @endif
        <section class="admin-panel"><h2>Add platform policy</h2>
            <form method="post" action="{{ route('super-admin.settings.policies.store') }}" class="admin-form">
                @csrf
                <div class="admin-form-grid">
                    <label class="admin-field"><span>Policy key</span><input name="key" pattern="[A-Za-z0-9_-]+" maxlength="255" required value="{{ old('key') }}" placeholder="returns-policy"></label>
                    <label class="admin-field"><span>Title</span><input name="title" maxlength="255" required value="{{ old('title') }}"></label>
                </div>
                <label class="admin-field"><span>Policy content</span><textarea name="body" rows="4" maxlength="20000">{{ old('body') }}</textarea></label>
                <button class="admin-button">Add policy</button>
            </form>
        </section>
        <section class="admin-panel"><h2>Existing policies</h2>
            @forelse ($policies as $policy)
                <article class="admin-record"><p class="admin-eyebrow">{{ $policy->key }}</p>
                    <form method="post" action="{{ route('super-admin.settings.policies.update', $policy) }}" class="admin-form">
                        @csrf @method('PUT')
                        <label class="admin-field"><span>Title</span><input name="title" maxlength="255" required value="{{ $policy->title }}"></label>
                        <label class="admin-field"><span>Policy content</span><textarea name="body" rows="5" maxlength="20000">{{ $policy->body }}</textarea></label>
                        <button class="admin-button admin-button-secondary">Save policy</button>
                    </form>
                </article>
            @empty<p class="admin-empty">No platform policies are configured.</p>@endforelse
            <div class="admin-pagination">{{ $policies->links() }}</div>
        </section>
    </section>
@endsection
