@php $active = $active ?? ''; @endphp
<a class="{{ $active === 'dashboard' ? 'active' : '' }}" href="{{ route('seller.dashboard') }}">Overview</a>
<a class="{{ $active === 'catalog' ? 'active' : '' }}" href="{{ route('seller.catalog') }}">Products</a>
<a class="{{ $active === 'orders' ? 'active' : '' }}" href="{{ route('seller.orders') }}">Orders</a>
<a class="{{ $active === 'returns' ? 'active' : '' }}" href="{{ route('seller.returns') }}">Returns</a>
<a class="{{ $active === 'reports' ? 'active' : '' }}" href="{{ route('seller.reports') }}">Reports</a>
<a class="{{ $active === 'promos' ? 'active' : '' }}" href="{{ route('seller.promos') }}">Promotions</a>
<a class="{{ $active === 'shipments' ? 'active' : '' }}" href="{{ route('seller.shipments') }}">Shipments</a>
<a class="{{ $active === 'store' ? 'active' : '' }}" href="{{ route('seller.store-profile') }}">Store</a>
