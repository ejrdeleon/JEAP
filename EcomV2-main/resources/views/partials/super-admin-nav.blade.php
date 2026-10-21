<a @class(['active' => request()->routeIs('super-admin.dashboard')]) href="{{ route('super-admin.dashboard') }}">Overview</a>
<a @class(['active' => request()->routeIs('super-admin.admins')]) href="{{ route('super-admin.admins') }}">Administrator accounts</a>
<a @class(['active' => request()->routeIs('super-admin.settings')]) href="{{ route('super-admin.settings') }}">Platform settings</a>
<a href="{{ route('admin.dashboard') }}">Admin workspace</a>
<a href="{{ route('admin.users') }}">Users</a>
<a href="{{ route('admin.verifications') }}">Verifications</a>
<a href="{{ route('logistics.shipments') }}">Logistics hub</a>
<a href="{{ route('seller.dashboard') }}">Seller dashboard</a>
<a href="{{ route('buyer.home') }}">Buyer home</a>
