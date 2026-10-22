@extends('layouts.dashboard')
@section('title', 'Shop vouchers')
@section('nav')
    <a href="{{ route('seller.dashboard') }}">Overview</a>
    <a href="{{ route('seller.catalog') }}">Products</a>
    <a href="{{ route('seller.orders') }}">Orders</a>
    <a class="active" href="{{ route('seller.promos') }}">Promotions</a>
    <a href="{{ route('seller.shipments') }}">Shipments</a>
@endsection
@section('content')
<div class="seller-page">
    <div class="seller-heading"><div><h1>Shop vouchers</h1><p>Buyers can enter these codes at checkout. The discount applies to your merchandise subtotal, not shipping.</p></div></div>
    @if(session('status'))<div class="seller-flash">{{ session('status') }}</div>@endif
    @if($errors->any())<div class="seller-errors">{{ $errors->first() }}</div>@endif
    <section class="seller-panel">
        <form method="post" action="{{ route('seller.promos.store') }}" class="voucher-form">
            @csrf
            <div class="s3-field"><label for="voucher-code">Code</label><input id="voucher-code" name="code" value="{{ old('code') }}" maxlength="20" required placeholder="SHOP10"></div>
            <div class="s3-field"><label for="voucher-type">Type</label><select id="voucher-type" name="type" required><option value="percent" @selected(old('type') === 'percent')>Percent</option><option value="fixed" @selected(old('type') === 'fixed')>Fixed ₱</option></select></div>
            <div class="s3-field"><label for="voucher-value">Value</label><input id="voucher-value" name="value" type="number" min="1" step="0.01" value="{{ old('value') }}" required></div>
            <div class="s3-field"><label for="voucher-min">Min. order ₱</label><input id="voucher-min" name="min_order" type="number" min="0" step="0.01" value="{{ old('min_order', 0) }}"></div>
            <div class="s3-field"><label for="voucher-cap">Max discount ₱</label><input id="voucher-cap" name="max_discount" type="number" min="0" step="0.01" value="{{ old('max_discount') }}"></div>
            <div class="s3-field"><label for="voucher-limit">Usage limit</label><input id="voucher-limit" name="usage_limit" type="number" min="1" value="{{ old('usage_limit') }}"></div>
            <div class="s3-field"><label for="voucher-start">Starts</label><input id="voucher-start" type="datetime-local" name="starts_at" value="{{ old('starts_at') }}"></div>
            <div class="s3-field"><label for="voucher-end">Expires</label><input id="voucher-end" type="datetime-local" name="expires_at" value="{{ old('expires_at') }}"></div>
            <button class="seller-primary" type="submit">Create voucher</button>
        </form>
    </section>
    <section class="seller-panel">
        @if($vouchers->isEmpty())
            <div class="seller-empty"><span>🎟</span><strong>No vouchers yet</strong><p>Create a shop voucher so buyers can apply it at checkout.</p></div>
        @else
            <div class="seller-table-wrap"><table class="seller-table"><thead><tr><th>Code</th><th>Offer</th><th>Rules</th><th>Used</th><th></th></tr></thead><tbody>
                @foreach($vouchers as $voucher)
                    <tr>
                        <td><strong>{{ $voucher->code }}</strong><small class="seller-subline">{{ $voucher->is_active ? 'Active' : 'Paused' }}</small></td>
                        <td>{{ $voucher->type === 'percent' ? number_format((float)$voucher->value, 0).'% off' : '₱'.number_format((float)$voucher->value, 2).' off' }}</td>
                        <td>Min ₱{{ number_format((float)$voucher->min_order, 2) }}@if($voucher->expires_at) · until {{ $voucher->expires_at->format('M j') }}@endif</td>
                        <td>{{ $voucher->used_count }}{{ $voucher->usage_limit ? ' / '.$voucher->usage_limit : '' }}</td>
                        <td>
                            <form method="post" action="{{ route('seller.promos.toggle', $voucher) }}" style="display:inline;">@csrf @method('PATCH')<button type="submit">{{ $voucher->is_active ? 'Pause' : 'Resume' }}</button></form>
                            <form method="post" action="{{ route('seller.promos.destroy', $voucher) }}" style="display:inline;" onsubmit="return confirm('Remove this voucher?')">@csrf @method('DELETE')<button type="submit">Remove</button></form>
                        </td>
                    </tr>
                @endforeach
            </tbody></table></div>
        @endif
    </section>
</div>
@endsection
