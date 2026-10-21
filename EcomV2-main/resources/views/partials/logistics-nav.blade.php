<a @class(['active' => request()->routeIs('logistics.dashboard', 'logistics.shipments')]) href="{{ route('logistics.shipments') }}">Shipments</a>
<a @class(['active' => request()->routeIs('logistics.couriers')]) href="{{ route('logistics.couriers') }}">Courier approvals</a>
@if (auth()->user()?->hasAnyRole(['logistics', 'super-admin']))
    <a @class(['active' => request()->routeIs('logistics.riders', 'logistics.riders.*')]) href="{{ route('logistics.riders') }}">Rider management</a>
@endif
