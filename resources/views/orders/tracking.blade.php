@extends('layouts.storefront')

@section('title', 'Track '.$shipment->tracking_number)
@section('crumb')
    <a href="{{ route('buyer.home') }}">My orders</a>
    <span>/</span>
    <span>JEAP Dash tracking</span>
@endsection

@section('content')
@php
    $steps = ['Shipped', 'Out for Delivery', 'Delivered'];
    $uiStep = min(3, max(0, (int) $progressStep));
    $status = $shipment->status;
    $isDelivered = $status === \App\Enums\ShipmentStatus::Delivered;
    $bannerLabel = $isDelivered && $shipment->delivered_at
        ? 'Delivered on '.$shipment->delivered_at->format('j M')
        : $status->label();
@endphp
<div class="mx-auto max-w-lg px-4 py-6 sm:px-0">
    <section class="overflow-hidden rounded-2xl bg-white shadow-sm ring-1 ring-slate-200">
        <div class="{{ $isDelivered ? 'bg-emerald-50' : 'bg-violet-50' }} px-5 py-4">
            <p class="flex items-center gap-2 text-sm font-semibold {{ $isDelivered ? 'text-emerald-700' : 'text-violet-800' }}">
                @if($isDelivered)
                    <span class="inline-flex h-6 w-6 items-center justify-center rounded-full bg-emerald-500 text-white" aria-hidden="true">✓</span>
                @else
                    <span class="inline-flex h-6 w-6 items-center justify-center rounded-full bg-violet-600 text-[10px] font-bold text-white" aria-hidden="true">JD</span>
                @endif
                {{ $bannerLabel }}
            </p>
            <p class="mt-1 text-xs text-slate-500">{{ $order->order_number }} · Cash on Delivery</p>
        </div>
        <ol class="grid grid-cols-3 gap-0 px-5 py-5" aria-label="Delivery progress">
            @foreach($steps as $index => $label)
                @php
                    $stepNumber = $index + 1;
                    $complete = $uiStep > $stepNumber;
                    $current = $uiStep === $stepNumber;
                    $active = $complete || $current;
                @endphp
                <li class="relative flex flex-col items-center text-center">
                    @if($index > 0)
                        <span class="absolute top-3 right-1/2 h-0.5 w-full {{ $uiStep >= $stepNumber ? 'bg-emerald-500' : 'bg-slate-200' }}" aria-hidden="true"></span>
                    @endif
                    <span class="relative z-10 flex h-6 w-6 items-center justify-center rounded-full text-[11px] font-bold {{ $active ? 'bg-emerald-500 text-white' : 'bg-slate-200 text-slate-500' }}">
                        {{ $complete || ($current && $isDelivered) ? '✓' : $stepNumber }}
                    </span>
                    <span class="mt-2 text-[11px] font-semibold leading-tight {{ $active ? 'text-slate-800' : 'text-slate-400' }}">{{ $label }}</span>
                </li>
            @endforeach
        </ol>
    </section>

    <section class="mt-4 rounded-2xl bg-white p-5 shadow-sm ring-1 ring-slate-200">
        <div class="flex items-start justify-between gap-3">
            <div class="flex items-center gap-3">
                <span class="flex h-11 w-11 items-center justify-center rounded-xl bg-violet-700 text-[10px] font-extrabold leading-tight text-white">JEAP<br>DASH</span>
                <div>
                    <p class="text-sm font-bold text-slate-900">{{ $shipment->courier_name }}</p>
                    <p class="font-mono text-sm tracking-wide text-slate-700" data-tracking-number>{{ $shipment->tracking_number }}</p>
                </div>
            </div>
            <button type="button" class="rounded-full border border-slate-200 px-3 py-1 text-xs font-semibold text-violet-700" data-copy-tracking>Copy</button>
        </div>
        @if($shipment->estimated_delivery_date)
            <p class="mt-3 text-xs text-slate-500">Estimated delivery {{ $shipment->estimated_delivery_date->format('j M Y') }}</p>
        @endif
        @if($shipment->courier)
            <p class="mt-1 text-xs text-slate-600">Rider {{ $shipment->courier->name }}@if($shipment->courier->phone) · <a class="text-violet-700" href="tel:{{ $shipment->courier->phone }}">{{ $shipment->courier->phone }}</a>@endif</p>
        @endif
        @if($shipment->proof_of_delivery_url)
            <button type="button" class="mt-3 text-sm font-semibold text-violet-700" data-open-pod>View Proof of Delivery</button>
        @endif
    </section>

    <section class="mt-4 rounded-2xl bg-white p-5 shadow-sm ring-1 ring-slate-200">
        <h2 class="mb-4 text-sm font-bold text-slate-900">Tracking details</h2>
        <ol class="relative">
            @forelse($checkpoints as $index => $checkpoint)
                @php $latest = $index === 0; @endphp
                <li class="relative grid grid-cols-[4.5rem_1.25rem_minmax(0,1fr)] gap-x-3 pb-6 last:pb-0">
                    <div class="pt-0.5 text-right text-[11px] leading-tight text-slate-500">
                        <div class="font-semibold text-slate-700">{{ $checkpoint->scanned_at?->format('d M') }}</div>
                        <div>{{ $checkpoint->scanned_at?->format('H:i') }}</div>
                    </div>
                    <div class="relative flex justify-center">
                        @unless($loop->last)
                            <span class="absolute top-3 bottom-[-6px] w-px bg-slate-200" aria-hidden="true"></span>
                        @endunless
                        <span class="relative z-10 mt-1 h-3 w-3 rounded-full {{ $latest ? 'bg-emerald-500 ring-4 ring-emerald-100' : 'bg-slate-300' }}"></span>
                    </div>
                    <div>
                        <p class="text-sm font-semibold {{ $latest ? 'text-emerald-700' : 'text-slate-800' }}">{{ $checkpoint->title }}</p>
                        @if($checkpoint->location)
                            <p class="mt-0.5 text-xs text-slate-500">{{ $checkpoint->location }}</p>
                        @endif
                        @if($checkpoint->notes)
                            <p class="mt-1 text-xs text-slate-600">{{ $checkpoint->notes }}</p>
                        @endif
                    </div>
                </li>
            @empty
                <li class="text-sm text-slate-500">Tracking updates will appear here as JEAP Dash scans this parcel.</li>
            @endforelse
        </ol>
    </section>

    <p class="mt-4 text-center text-xs text-slate-500">
        <a class="font-semibold text-violet-700" href="{{ route('buyer.orders.track', $order) }}">Order record and after-sale</a>
    </p>
</div>

@if($shipment->proof_of_delivery_url)
    <dialog id="pod-modal" class="w-[min(92vw,32rem)] rounded-2xl p-0 shadow-xl backdrop:bg-black/50">
        <div class="flex items-center justify-between border-b border-slate-200 px-4 py-3">
            <strong class="text-sm">Proof of Delivery</strong>
            <form method="dialog"><button class="text-sm text-slate-500" type="submit">Close</button></form>
        </div>
        <img src="{{ $shipment->proof_of_delivery_url }}" alt="Proof of delivery" class="max-h-[70vh] w-full object-contain bg-slate-50">
        @if($shipment->recipient_name)
            <p class="px-4 py-3 text-xs text-slate-500">Received by {{ $shipment->recipient_name }}</p>
        @endif
    </dialog>
@endif

<script>
    document.querySelectorAll('[data-copy-tracking]').forEach((button) => {
        button.addEventListener('click', async () => {
            const value = document.querySelector('[data-tracking-number]')?.textContent?.trim();
            if (!value) return;
            await navigator.clipboard.writeText(value);
            button.textContent = 'Copied';
            setTimeout(() => { button.textContent = 'Copy'; }, 1600);
        });
    });
    document.querySelectorAll('[data-open-pod]').forEach((button) => {
        button.addEventListener('click', () => document.getElementById('pod-modal')?.showModal());
    });
</script>
@endsection
