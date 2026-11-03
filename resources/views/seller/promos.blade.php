@extends('layouts.dashboard')
@section('title', 'Shop vouchers')
@section('nav')
    @include('partials.seller-nav', ['active' => 'promos'])
@endsection
@section('content')
<div class="seller-page promo-page">
    <div class="seller-heading">
        <div>
            <span class="seller-eyebrow">SELLER CENTRE / PROMOTIONS</span>
            <h1>Shop vouchers</h1>
            <p>Buyers enter these codes at checkout. The discount applies to your merchandise subtotal, not the ₱{{ number_format(\App\Commerce\InventoryPolicy::shippingFee(), 0) }} shipping fee.</p>
        </div>
    </div>
    @if(session('status'))<div class="seller-flash">{{ session('status') }}</div>@endif
    @if($errors->any())<div class="seller-errors"><strong>Please check the voucher details.</strong><ul>@foreach($errors->all() as $error)<li>{{ $error }}</li>@endforeach</ul></div>@endif

    <div class="promo-layout {{ $vouchers->isEmpty() ? '' : 'has-vouchers' }}">
        <section class="seller-panel promo-create">
            <div class="seller-panel-head">
                <div>
                    <h2>Create a voucher</h2>
                    <p>Percent off is capped at 80%. Cash on Delivery still collects shipping in full.</p>
                </div>
            </div>
            <form method="post" action="{{ route('seller.promos.store') }}" class="promo-form" data-voucher-form>
                @csrf
                <div class="promo-group">
                    <h3>Offer</h3>
                    <label class="seller-field seller-field-wide">Code
                        <input id="voucher-code" name="code" value="{{ old('code') }}" maxlength="20" required placeholder="SHOP10" autocomplete="off" spellcheck="false">
                        <small>Letters, numbers, hyphen or underscore.</small>
                    </label>
                    <label class="seller-field">Type
                        <select id="voucher-type" name="type" required>
                            <option value="percent" @selected(old('type', 'percent') === 'percent')>Percent off</option>
                            <option value="fixed" @selected(old('type') === 'fixed')>Fixed ₱ off</option>
                        </select>
                    </label>
                    <label class="seller-field">Value
                        <input id="voucher-value" name="value" type="number" min="1" step="0.01" value="{{ old('value') }}" required placeholder="10">
                        <small data-voucher-value-hint>Percent off merchandise, up to 80%.</small>
                    </label>
                </div>
                <div class="promo-group">
                    <h3>Rules</h3>
                    <label class="seller-field">Minimum order
                        <div class="seller-input-prefix"><span>₱</span><input id="voucher-min" name="min_order" type="number" min="0" step="0.01" value="{{ old('min_order', 0) }}" placeholder="0.00"></div>
                    </label>
                    <label class="seller-field">Max discount <span>(optional)</span>
                        <div class="seller-input-prefix"><span>₱</span><input id="voucher-cap" name="max_discount" type="number" min="0" step="0.01" value="{{ old('max_discount') }}" placeholder="0.00"></div>
                    </label>
                    <label class="seller-field seller-field-wide">Usage limit <span>(optional)</span>
                        <input id="voucher-limit" name="usage_limit" type="number" min="1" value="{{ old('usage_limit') }}" placeholder="Unlimited">
                    </label>
                </div>
                <div class="promo-group">
                    <h3>Schedule</h3>
                    <label class="seller-field">Starts
                        <input id="voucher-start" type="datetime-local" name="starts_at" value="{{ old('starts_at') }}">
                        <small>Leave blank to start as soon as you create it.</small>
                    </label>
                    <label class="seller-field">Expires
                        <input id="voucher-end" type="datetime-local" name="expires_at" value="{{ old('expires_at') }}">
                        <small>Leave blank if it should not expire.</small>
                    </label>
                </div>
                <div class="seller-form-actions">
                    <button class="seller-primary" type="submit">Create voucher</button>
                </div>
            </form>
        </section>

        <section class="seller-panel promo-list-panel">
            <div class="seller-panel-head">
                <div>
                    <h2>Your vouchers</h2>
                    <p>{{ $vouchers->isEmpty() ? 'New codes appear here after you create them.' : $vouchers->count().' '.Str::plural('voucher', $vouchers->count()).' in your shop.' }}</p>
                </div>
            </div>
            @if($vouchers->isEmpty())
                <div class="seller-empty promo-empty">
                    <span aria-hidden="true">%</span>
                    <strong>No vouchers yet</strong>
                    <p>Create a shop voucher so buyers can apply it at checkout.</p>
                    <ul>
                        <li>Keep codes short, like <em>SHOP10</em></li>
                        <li>Percent off is capped at 80%</li>
                        <li>Discount never applies to ₱{{ number_format(\App\Commerce\InventoryPolicy::shippingFee(), 0) }} shipping</li>
                    </ul>
                </div>
            @else
                <div class="promo-list">
                    @foreach($vouchers as $voucher)
                        <article class="promo-card">
                            <div class="promo-card-top">
                                <div>
                                    <strong class="promo-code">{{ $voucher->code }}</strong>
                                    <span class="seller-badge {{ $voucher->is_active ? 'is-active' : '' }}">{{ $voucher->is_active ? 'Active' : 'Paused' }}</span>
                                </div>
                                <p class="promo-offer">{{ $voucher->type === 'percent' ? number_format((float) $voucher->value, 0).'% off merchandise' : '₱'.number_format((float) $voucher->value, 2).' off merchandise' }}</p>
                            </div>
                            <ul class="promo-rules">
                                <li>Min order ₱{{ number_format((float) $voucher->min_order, 2) }}</li>
                                @if($voucher->max_discount !== null)<li>Cap ₱{{ number_format((float) $voucher->max_discount, 2) }}</li>@endif
                                <li>Used {{ $voucher->used_count }}{{ $voucher->usage_limit ? ' / '.$voucher->usage_limit : '' }}</li>
                                @if($voucher->starts_at)<li>Starts {{ $voucher->starts_at->timezone(config('app.timezone'))->format('M j, Y · g:i A') }}</li>@endif
                                @if($voucher->expires_at)<li>Until {{ $voucher->expires_at->timezone(config('app.timezone'))->format('M j, Y · g:i A') }}</li>@endif
                            </ul>
                            <div class="promo-card-actions">
                                <form method="post" action="{{ route('seller.promos.toggle', $voucher) }}">
                                    @csrf
                                    @method('PATCH')
                                    <button class="seller-secondary" type="submit">{{ $voucher->is_active ? 'Pause' : 'Resume' }}</button>
                                </form>
                                <form method="post" action="{{ route('seller.promos.destroy', $voucher) }}" data-confirm="Remove this voucher?">
                                    @csrf
                                    @method('DELETE')
                                    <button class="promo-remove" type="submit">Remove</button>
                                </form>
                            </div>
                        </article>
                    @endforeach
                </div>
            @endif
        </section>
    </div>
</div>
@endsection
