<?php

namespace App\Http\Controllers\Shipping;

use App\Http\Controllers\Controller;
use App\Models\Parcel;
use App\Models\Shipment;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\View\View;

class PageController extends Controller
{
    public function home(): View
    {
        return view('shipping.home');
    }

    public function track(Request $request): View
    {
        $parcel = null;
        $shipment = null;
        $events = collect();
        $trackingNumber = trim((string) $request->query('tracking_number', ''));

        if ($trackingNumber !== '') {
            $data = $request->validate([
                'tracking_number' => ['required', 'string', 'alpha_dash', 'max:40'],
            ]);
            $trackingNumber = $data['tracking_number'];
            $shipment = Shipment::query()
                ->whereRaw('UPPER(tracking_number) = ?', [Str::upper($trackingNumber)])
                ->with(['checkpoints', 'order'])
                ->first();

            if ($shipment && auth()->id() && $shipment->order?->buyer_id === auth()->id()) {
                return redirect()->route('orders.tracking', $shipment->order);
            }

            $parcel = Parcel::query()
                ->whereRaw('UPPER(tracking_number) = ?', [Str::upper($trackingNumber)])
                ->with(['order.statusHistories', 'scans'])
                ->first();

            if ($shipment) {
                $events = $shipment->checkpoints->sortBy('scanned_at')->values()->map(fn ($checkpoint) => [
                    'label' => $checkpoint->title,
                    'at' => $checkpoint->scanned_at,
                    'sort_at' => $checkpoint->scanned_at?->timestamp ?? 0,
                ]);
            } elseif ($parcel?->order) {
                $events = $parcel->order->statusHistories->map(fn ($history) => [
                    'label' => str($history->to_status?->value ?? 'Order update')->replace('_', ' ')->title()->toString(),
                    'at' => $history->created_at,
                    'sort_at' => $history->created_at?->timestamp ?? 0,
                ])->concat($parcel->scans->map(fn ($scan) => [
                    'label' => match ($scan->location_type) {
                        'seller' => 'Parcel picked up from seller',
                        'hub' => 'Shipment received at logistics hub',
                        'assignment' => 'Rider assignment updated',
                        default => 'Shipment scan recorded',
                    },
                    'at' => $scan->created_at,
                    'sort_at' => $scan->created_at?->timestamp ?? 0,
                ]))->sortBy('sort_at')->values();
            }
        }

        return view('shipping.track', [
            'parcel' => $parcel,
            'shipment' => $shipment,
            'events' => $events,
            'trackingNumber' => $trackingNumber,
            'notFound' => $trackingNumber !== '' && $parcel === null && $shipment === null,
        ]);
    }

    public function ship(): RedirectResponse|View
    {
        $user = auth()->user();
        if ($user?->hasRole('seller')) {
            return to_route('seller.shipments');
        }
        if ($user?->hasRole('logistics')) {
            return to_route('logistics.shipments');
        }
        if ($user?->hasRole('courier')) {
            return to_route('courier.dashboard');
        }

        return view('shipping.info', [
            'title' => 'How JEAP shipping works',
            'heading' => 'Sellers prepare, '.config('jeap.courier_name').' delivers',
        ]);
    }

    public function shipments(): RedirectResponse
    {
        $user = auth()->user();
        if ($user?->hasRole('seller')) {
            return to_route('seller.shipments');
        }
        if ($user?->hasRole('logistics')) {
            return to_route('logistics.shipments');
        }
        if ($user?->hasRole('courier')) {
            return to_route('courier.dashboard');
        }

        return to_route('buyer.home');
    }

    public function details(Parcel $parcel): RedirectResponse
    {
        $user = auth()->user();
        abort_unless(
            $user && ($user->hasAnyRole(['admin', 'logistics', 'courier', 'seller']) || $parcel->order?->buyer_id === $user->id),
            403
        );

        if ($parcel->order?->buyer_id === $user->id) {
            return to_route('buyer.orders.track', $parcel->order);
        }
        if ($user->hasRole('seller')) {
            return to_route('seller.shipments');
        }
        if ($user->hasRole('courier')) {
            return to_route('courier.dashboard');
        }

        return to_route('logistics.shipments');
    }

    public function services(): View
    {
        return view('shipping.info', [
            'title' => 'Delivery services',
            'heading' => config('jeap.courier_name').' across the Philippines',
        ]);
    }

    public function pricing(): View
    {
        return view('shipping.info', [
            'title' => 'Shipping price',
            'heading' => 'Flat ₱'.number_format(\App\Commerce\InventoryPolicy::shippingFee(), 0).' shipping',
        ]);
    }

    public function account(): RedirectResponse
    {
        return to_route('profile');
    }
}
