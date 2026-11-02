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
        <section class="admin-panel">
            <h2>Logistics commission</h2>
            <p class="admin-subtitle">Logistics keeps this percent of merchandise subtotal. Shipping is separate and is not part of the cut. Existing orders keep the rate recorded when they were placed.</p>
            <form method="post" action="{{ route('admin.commission-rate.update') }}" class="admin-form" style="max-width: 360px; margin-top: 14px;">
                @csrf @method('PUT')
                <label class="admin-field"><span>Commission rate (%)</span>
                    <input type="number" name="commission_rate" min="1" max="50" step="0.01" required value="{{ old('commission_rate', number_format($commissionRate, 2, '.', '')) }}">
                </label>
                <button class="admin-button">Save commission rate</button>
            </form>
        </section>
        <section class="admin-panel">
            <h2>Shipping and stock rules</h2>
            <p class="admin-subtitle">These apply to new listings, carts, and checkouts. Existing orders keep the shipping they already paid.</p>
            <form method="post" action="{{ route('super-admin.settings.commerce.update') }}" class="admin-form" style="max-width: 420px; margin-top: 14px;">
                @csrf @method('PUT')
                <label class="admin-field"><span>Flat shipping (₱)</span>
                    <input type="number" name="shipping_fee" min="0" max="9999" step="0.01" required value="{{ old('shipping_fee', number_format($shippingFee, 2, '.', '')) }}">
                </label>
                <label class="admin-field"><span>Minimum stock to sell</span>
                    <input type="number" name="min_sellable_stock" min="1" max="1000" required value="{{ old('min_sellable_stock', $minSellableStock) }}">
                </label>
                <label class="admin-field"><span>Max units of one product in cart</span>
                    <input type="number" name="max_qty_per_product" min="1" max="100" required value="{{ old('max_qty_per_product', $maxQtyPerProduct) }}">
                </label>
                <button class="admin-button">Save commerce rules</button>
            </form>
        </section>
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
