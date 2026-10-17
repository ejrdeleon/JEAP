<?php

namespace App\Http\Controllers\Shipping;

use App\Http\Controllers\Controller;
use App\Models\Parcel;
use Illuminate\Http\Request;
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
        $events = collect();
        $trackingNumber = trim((string) $request->query('tracking_number', ''));

        if ($trackingNumber !== '') {
            $data = $request->validate([
                'tracking_number' => ['required', 'string', 'alpha_dash', 'max:40'],
            ]);
            $trackingNumber = $data['tracking_number'];
            $parcel = Parcel::query()
                ->where('tracking_number', $trackingNumber)
                ->with(['order.statusHistories', 'scans'])
                ->firstOrFail();

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

        return view('shipping.track', compact('parcel', 'events', 'trackingNumber'));
    }

    public function ship(): View
    {
        return view('shipping.stub', ['figma' => '03_Ship_Now 1', 'title' => 'Ship Now']);
    }

    public function shipments(): View
    {
        return view('shipping.stub', ['figma' => '04_My_Shipments 1', 'title' => 'My Shipments']);
    }

    public function details(Parcel $parcel): View
    {
        $user = auth()->user();
        abort_unless(
            $user && ($user->hasAnyRole(['admin', 'logistics', 'courier', 'seller']) || $parcel->order?->buyer_id === $user->id),
            403
        );

        return view('shipping.stub', ['figma' => '05_Shipment_Details 1', 'title' => 'Shipment '.$parcel->tracking_number]);
    }

    public function services(): View
    {
        return view('shipping.stub', ['figma' => '06_Services 1', 'title' => 'Services']);
    }

    public function pricing(): View
    {
        return view('shipping.stub', ['figma' => '07_Pricing_Calculator 1', 'title' => 'Pricing Calculator']);
    }

    public function account(): View
    {
        return view('shipping.stub', ['figma' => '08_My_Account_Profile 1', 'title' => 'Shipping Account']);
    }
}
