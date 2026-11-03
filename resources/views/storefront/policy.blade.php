@extends('layouts.storefront')
@section('title', $policy->title)
@section('crumb')
    <a href="{{ route('help') }}">Help</a>
    <span>/</span>
    <span>{{ $policy->title }}</span>
@endsection
@section('content')
@php
    $paragraphs = collect(preg_split("/\R\s*\R/u", trim((string) $policy->body)))
        ->map(fn ($block) => trim(preg_replace('/\s+/u', ' ', $block) ?? ''))
        ->filter();
    $otherKey = $policy->key === 'privacy' ? 'terms' : 'privacy';
    $otherTitle = $policy->key === 'privacy' ? 'Terms of use' : 'Privacy policy';
@endphp
<section class="s3-main policy-page">
    <header class="policy-heading">
        <p class="status-kicker">Legal</p>
        <h1>{{ $policy->title }}</h1>
        <p>{{ $policy->key === 'privacy' ? 'What JEAP collects and how we use it.' : 'Rules for shopping, selling, and delivery on JEAP.' }}</p>
    </header>

    <article class="policy-card">
        @forelse($paragraphs as $paragraph)
            <p>{{ $paragraph }}</p>
        @empty
            <p>This policy is not available yet.</p>
        @endforelse
    </article>

    <nav class="policy-actions" aria-label="Policy links">
        <a class="status-btn status-btn--ghost" href="{{ route('help') }}">Back to help</a>
        <a class="status-link" href="{{ route('policies.show', $otherKey) }}">{{ $otherTitle }}</a>
        <a class="status-link" href="{{ route('contact') }}">Contact JEAP</a>
    </nav>
</section>
@endsection
