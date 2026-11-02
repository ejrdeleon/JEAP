@extends('layouts.storefront')
@section('title', $policy->title)
@section('crumb')
    <a href="{{ route('help') }}">Help</a><span>/</span><span>{{ $policy->title }}</span>
@endsection
@section('content')
<section class="s3-main help-page">
    <h1>{{ $policy->title }}</h1>
    <div class="policy-body">{!! nl2br(e($policy->body)) !!}</div>
    <p><a class="s3-link" href="{{ route('help') }}">Back to help</a></p>
</section>
@endsection
