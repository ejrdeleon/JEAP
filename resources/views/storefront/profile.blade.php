@extends('layouts.storefront')

@section('title', 'My profile | JEAP')
@section('crumb')
    <span>My account</span><span>/</span><span>Profile</span>
@endsection

@section('content')
<div class="account-page">
    <header class="account-page-heading">
        <div><span class="account-eyebrow">MY JEAP ACCOUNT</span><h1>Profile</h1><p>The same account details buyers, sellers, and riders use across JEAP.</p></div>
    </header>

    <div class="account-page-layout">
        <aside class="account-side-card" aria-label="Account navigation">
            <div class="account-avatar" aria-hidden="{{ $user->avatarUrl() ? 'false' : 'true' }}">
                @if($user->avatarUrl())
                    <img src="{{ $user->avatarUrl() }}" alt="{{ $user->name }}">
                @else
                    {{ mb_strtoupper(mb_substr($user->first_name ?: $user->email, 0, 1)) }}
                @endif
            </div>
            <strong>{{ $user->name }}</strong>
            <a class="account-email" href="mailto:{{ $user->email }}">{{ $user->email }}</a>
            @include('partials.account-nav', ['user' => $user])
            <x-logout-form button-class="account-logout">Sign out</x-logout-form>
        </aside>

        <section class="account-form-card" aria-labelledby="account-form-title">
            @if ($errors->any())<div class="account-message is-error" role="alert">{{ $errors->first() }}</div>@endif
            @if (session('toast'))<div class="account-message is-success" role="status">{{ session('toast') }}</div>@endif
            <div class="account-form-heading"><div><span class="account-eyebrow">PERSONAL DETAILS</span><h2 id="account-form-title">Your profile</h2></div><span class="account-status status-{{ str($user->status->value)->slug('_') }}">{{ str($user->status->value)->replace('_', ' ')->title() }}</span></div>
            <form method="post" action="{{ route('profile.update') }}" enctype="multipart/form-data">
                @csrf
                <div class="account-field-grid">
                    <div class="account-field account-field-wide">
                        <label for="profile-avatar">Profile photo</label>
                        <div class="account-avatar-row">
                            <div class="account-avatar account-avatar-preview">
                                <img id="profile-avatar-preview" src="{{ $user->avatarUrl() ?: '' }}" alt="" @unless($user->avatarUrl()) hidden @endunless>
                                <span id="profile-avatar-fallback" @if($user->avatarUrl()) hidden @endif>{{ mb_strtoupper(mb_substr($user->first_name ?: $user->email, 0, 1)) }}</span>
                            </div>
                            <input id="profile-avatar" type="file" name="avatar" accept="image/jpeg,image/png,image/webp">
                        </div>
                        <small>JPG, PNG or WEBP · up to 5 MB. The photo is stored on this server and served from JEAP, not a broken storage link.</small>
                        @error('avatar')<small>{{ $message }}</small>@enderror
                    </div>
                    <div class="account-field"><label for="profile-first-name">First name</label><input id="profile-first-name" name="first_name" value="{{ old('first_name', $user->first_name) }}" autocomplete="given-name" required @error('first_name') aria-invalid="true" @enderror>@error('first_name')<small>{{ $message }}</small>@enderror</div>
                    <div class="account-field"><label for="profile-last-name">Last name</label><input id="profile-last-name" name="last_name" value="{{ old('last_name', $user->last_name) }}" autocomplete="family-name" required @error('last_name') aria-invalid="true" @enderror>@error('last_name')<small>{{ $message }}</small>@enderror</div>
                    <div class="account-field"><label for="profile-email">Email address</label><input id="profile-email" type="email" name="email" value="{{ old('email', $user->email) }}" autocomplete="email" required @error('email') aria-invalid="true" @enderror>@error('email')<small>{{ $message }}</small>@enderror</div>
                    <div class="account-field"><label for="profile-phone">Phone number <span>Optional</span></label><input id="profile-phone" type="tel" name="phone" value="{{ old('phone', $user->phone) }}" autocomplete="tel" @error('phone') aria-invalid="true" @enderror>@error('phone')<small>{{ $message }}</small>@enderror</div>
                    <div class="account-field"><label for="profile-sex">Gender <span>Optional</span></label><select id="profile-sex" name="sex"><option value="">Prefer not to say</option><option value="female" @selected(old('sex', $user->sex) === 'female')>Female</option><option value="male" @selected(old('sex', $user->sex) === 'male')>Male</option><option value="other" @selected(old('sex', $user->sex) === 'other')>Other</option></select></div>
                    <div class="account-field"><label for="profile-birthday">Date of birth <span>Optional</span></label><input id="profile-birthday" type="date" name="birthday" value="{{ old('birthday', $user->birthday?->toDateString()) }}" max="{{ now()->subYears(18)->toDateString() }}">@error('birthday')<small>{{ $message }}</small>@enderror</div>
                </div>
                <div class="account-form-footer"><p>Account type: {{ $user->roles->pluck('name')->map(fn ($role) => str($role)->replace('-', ' ')->title())->join(', ') ?: 'Member' }}@if($user->google_id) · Google linked @endif</p><button type="submit">Save changes</button></div>
            </form>
        </section>
    </div>
</div>
<script>
    const avatarInput = document.querySelector('#profile-avatar');
    const preview = document.querySelector('#profile-avatar-preview');
    const fallback = document.querySelector('#profile-avatar-fallback');
    avatarInput?.addEventListener('change', () => {
        const file = avatarInput.files?.[0];
        if (!file || !preview) return;
        preview.src = URL.createObjectURL(file);
        preview.hidden = false;
        if (fallback) fallback.hidden = true;
    });
</script>
@endsection
