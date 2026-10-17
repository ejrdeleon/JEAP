@extends('layouts.storefront')

@section('title', 'Contact')
@section('crumb')
    <a href="{{ route('products.index') }}">Shop</a>
    <span>/</span>
    <span>Contact</span>
@endsection

@section('content')
<section class="s3-main" data-figma="Contact 7:247">
    <h3 style="padding:30px 30px 0;font-size:16px;margin:0;">ready to work with us</h3>
    <div class="s3-contact">
        <form onsubmit="event.preventDefault(); this.querySelector('[data-sent]').hidden=false;">
            <p>Contact us for all your questions and opinions</p>
            <div class="s3-two">
                <div class="s3-field"><label>First Name</label><input name="first_name" required></div>
                <div class="s3-field"><label>Last Name</label><input name="last_name" required></div>
            </div>
            <div class="s3-field"><label>Email Address</label><input type="email" required style="width:100%"></div>
            <div class="s3-field"><label>Phone Number (optional)</label><input style="width:100%"></div>
            <div class="s3-field">
                <label>Country / Region</label>
                <select style="width:100%">
                    <option>Philippines</option>
                    <option>United States (US)</option>
                </select>
            </div>
            <div class="s3-field"><label>Subject (optional)</label><input style="width:100%"></div>
            <div class="s3-field">
                <label>Message</label>
                <textarea placeholder="Note about your order, e.g. special note for delivery" style="width:100%"></textarea>
            </div>
            <label style="display:flex;gap:8px;font-size:13px;margin:12px 0 24px;">
                <input type="checkbox"> I want to receive news and updates once in a while. By submitting, I’m agreed to the Policy
            </label>
            <button class="s3-btn" type="submit" style="min-width:153px;">send message</button>
            <p data-sent hidden>Thanks — JEAP received your message.</p>
        </form>
        <div>
            <div class="s3-cinfo">
                <small>philippines (head quater)</small>
                <p><strong>Laguna, Philippines · in-house sorting center</strong><br>{{ config('jeap.hotline') }}<br>hello@jeap.test</p>
                <small>branch</small>
                <p>Shop smart. Delivered easy.</p>
                <div class="s3-soc"><span></span><span></span><span></span><span></span><span></span></div>
            </div>
            <img src="{{ asset('images/storefront/contact-side.svg') }}" alt="" width="524" height="380" style="margin-top:10px;width:100%;height:380px;object-fit:cover;">
        </div>
    </div>
    <h3 style="padding:0 30px;font-size:16px;">find us on google map</h3>
    <div class="s3-map">Laguna, Philippines — JEAP sorting center</div>
</section>
@endsection
