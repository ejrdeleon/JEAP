@extends('layouts.storefront')

@section('title', 'Contact JEAP')
@section('crumb')
    <span>Contact</span>
@endsection

@section('content')
<div class="contact-page" data-figma="Contact 7:247">
    <section class="contact-hero">
        <div>
            <span class="contact-eyebrow">WE’RE HERE TO HELP</span>
            <h1>Talk to JEAP.</h1>
            <p>Questions about JEAP or an order? Send our team a message, or use your account and shipment tools.</p>
            <div class="contact-hero-actions">
                <a class="contact-call-button" href="#contact-form">Send a message</a>
                <a class="contact-track-link" href="{{ route('shipping.track') }}">Track a shipment</a>
            </div>
        </div>
        <div class="contact-illustration"><img src="{{ asset('images/storefront/contact-side.svg') }}" alt="" width="401" height="327"></div>
    </section>

    <section class="contact-options" aria-label="Contact options">
        <article class="contact-option-card">
            <span class="contact-option-icon" aria-hidden="true">01</span>
            <div><h2>Message support</h2><p>Send a note from this page and JEAP will review it in the support inbox.</p><a href="#contact-form">Open the form <span aria-hidden="true">→</span></a></div>
            <small>Support</small>
        </article>
        <article class="contact-option-card">
            <span class="contact-option-icon" aria-hidden="true">02</span>
            <div><h2>Check a shipment</h2><p>Enter the tracking number to view the latest recorded updates.</p><a href="{{ route('shipping.track') }}">Go to tracking <span aria-hidden="true">→</span></a></div>
            <small>Order support</small>
        </article>
        <article class="contact-option-card">
            <span class="contact-option-icon" aria-hidden="true">03</span>
            <div><h2>Manage your account</h2><p>Review your profile, orders, and saved delivery details.</p><a href="{{ auth()->check() ? route('profile') : route('login') }}">{{ auth()->check() ? 'Open my account' : 'Sign in to JEAP' }} <span aria-hidden="true">→</span></a></div>
            <small>Account support</small>
        </article>
    </section>

    <section class="contact-form-grid" aria-label="Contact support">
        <div class="contact-form-panel" id="contact-form">
            <div class="contact-section-heading"><span class="contact-eyebrow">CONTACT SUPPORT</span><h2>Send us a message</h2><p>Share a few details and our team can follow up about your question.</p></div>
            @if (session('contact_sent'))
                <div class="contact-feedback is-success" role="status">Your message was received. JEAP support will review it.</div>
            @endif
            @if (session('contact_error'))
                <div class="contact-feedback is-error" role="alert">{{ session('contact_error') }}</div>
            @endif
            @if ($errors->any())
                <div class="contact-feedback is-error" role="alert">Please check the highlighted fields and try again.</div>
            @endif
            <form class="contact-form" method="post" action="{{ route('contact.submit') }}" data-contact-form>
                @csrf
                <div class="contact-honeypot" aria-hidden="true"><label for="contact-website">Leave this field empty</label><input id="contact-website" name="website" tabindex="-1" autocomplete="off"></div>
                <div class="contact-form-row">
                    <div class="contact-field"><label for="contact-name">Full name</label><input id="contact-name" name="full_name" value="{{ old('full_name', auth()->user()->name ?? '') }}" autocomplete="name" maxlength="120" required @error('full_name') aria-invalid="true" @enderror>@error('full_name')<small>{{ $message }}</small>@enderror</div>
                    <div class="contact-field"><label for="contact-email">Email address</label><input id="contact-email" type="email" name="email" value="{{ old('email', auth()->user()->email ?? '') }}" autocomplete="email" maxlength="255" required @error('email') aria-invalid="true" @enderror>@error('email')<small>{{ $message }}</small>@enderror</div>
                </div>
                <div class="contact-field"><label for="contact-category">What can we help with?</label><select id="contact-category" name="category" required @error('category') aria-invalid="true" @enderror><option value="">Choose a topic</option><option value="order" @selected(old('category') === 'order')>Order assistance</option><option value="delivery" @selected(old('category') === 'delivery')>Delivery and tracking</option><option value="account" @selected(old('category') === 'account')>Account support</option><option value="general" @selected(old('category') === 'general')>General inquiry</option></select>@error('category')<small>{{ $message }}</small>@enderror</div>
                <div class="contact-field"><label for="contact-order">Order number <span>Optional</span></label><input id="contact-order" name="order_number" value="{{ old('order_number') }}" maxlength="80" autocomplete="off" @error('order_number') aria-invalid="true" @enderror>@error('order_number')<small>{{ $message }}</small>@enderror</div>
                <div class="contact-field"><label for="contact-message">Message</label><textarea id="contact-message" name="message" rows="5" minlength="10" maxlength="5000" required @error('message') aria-invalid="true" @enderror>{{ old('message') }}</textarea>@error('message')<small>{{ $message }}</small>@enderror</div>
                <button class="contact-submit" type="submit"><span data-contact-submit-label>Send message</span><span aria-hidden="true">→</span></button>
            </form>
        </div>

        <aside class="contact-faq-panel">
            <span class="contact-eyebrow">QUICK ANSWERS</span><h2>Before you message</h2>
            <details><summary>Where can I find my tracking number?</summary><p>Open your JEAP account, choose your order, and look for its shipment details.</p><a href="{{ route('shipping.track') }}">Track a shipment <span aria-hidden="true">→</span></a></details>
            <details><summary>What information does tracking show?</summary><p>The public tracking page shows shipment status and recorded updates. Sign in to see full order information.</p><a href="{{ route('shipping.track') }}">Open order tracking <span aria-hidden="true">→</span></a></details>
            <details><summary>Which payment method can I use?</summary><p>The current JEAP checkout supports Cash on Delivery.</p><a href="{{ route('products.index') }}">Browse products <span aria-hidden="true">→</span></a></details>
        </aside>
    </section>

    <section class="contact-bottom-note">
        <div><span class="contact-eyebrow">JEAP MARKETPLACE</span><h2>Shop smart. Delivered easy.</h2></div>
        <a href="{{ route('products.index') }}">Browse products <span aria-hidden="true">→</span></a>
    </section>
</div>
<script>
    document.querySelectorAll('[data-contact-form]').forEach((form) => {
        form.addEventListener('submit', () => {
            const button = form.querySelector('button[type="submit"]');
            const label = form.querySelector('[data-contact-submit-label]');
            if (!button || button.disabled) return;
            button.disabled = true;
            button.setAttribute('aria-busy', 'true');
            if (label) label.textContent = 'Sending…';
        });
    });
</script>
@endsection
