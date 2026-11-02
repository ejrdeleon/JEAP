@php $active = $active ?? ''; @endphp
<a class="{{ $active === 'dashboard' ? 'active' : '' }}" href="{{ route('admin.dashboard') }}">Overview</a>
<a class="{{ $active === 'verifications' ? 'active' : '' }}" href="{{ route('admin.verifications') }}">Verifications</a>
<a class="{{ $active === 'cms' ? 'active' : '' }}" href="{{ route('admin.cms') }}">Marketplace CMS</a>
<a class="{{ $active === 'users' ? 'active' : '' }}" href="{{ route('admin.users') }}">Users</a>
<a class="{{ $active === 'returns' ? 'active' : '' }}" href="{{ route('admin.returns') }}">Returns</a>
<a class="{{ $active === 'disputes' ? 'active' : '' }}" href="{{ route('admin.disputes') }}">Disputes</a>
<a class="{{ $active === 'contact' ? 'active' : '' }}" href="{{ route('admin.contact-messages') }}">Contact messages</a>
<a class="{{ $active === 'reports' ? 'active' : '' }}" href="{{ route('admin.reports') }}">Reports</a>
@if (auth()->user()->hasRole('super-admin'))
    <a href="{{ route('super-admin.dashboard') }}">Super admin</a>
@endif
