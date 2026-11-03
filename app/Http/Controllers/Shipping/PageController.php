<?php

namespace App\Http\Controllers\Shipping;

use App\Enums\OrderStatus;
use App\Enums\ShipmentStatus;
use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Parcel;
use App\Models\Shipment;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use Illuminate\Support\Str;
use Illuminate\View\View;

class PageController extends Controller
{
    public function home(): RedirectResponse
    {
        return redirect()->route('shipping.track', [], 301);
    }

    public function track(Request $request): View|RedirectResponse
    {
        $trackingNumber = trim((string) $request->query('tracking_number', ''));
        $lookup = [
            'shipment' => null,
            'parcel' => null,
            'events' => collect(),
            'found' => false,
        ];

        if ($trackingNumber !== '') {
            $data = $request->validate([
                'tracking_number' => ['required', 'string', 'alpha_dash', 'max:40'],
            ]);
            $trackingNumber = $data['tracking_number'];
            $lookup = $this->findTrackedShipment($trackingNumber);

            if ($lookup['shipment'] && auth()->id() && $lookup['shipment']->order?->buyer_id === auth()->id()) {
                return redirect()->route('orders.tracking', $lookup['shipment']->order);
            }
        }

        $currentOrders = $this->currentOrdersFor($request->user());

        return view('shipping.track', [
            'parcel' => $lookup['parcel'],
            'shipment' => $lookup['shipment'],
            'events' => $lookup['events'],
            'lookupCard' => $lookup['found']
                ? $this->presentLookup($lookup['shipment'], $lookup['parcel'], $lookup['events'])
                : null,
            'trackingNumber' => $trackingNumber,
            'notFound' => $trackingNumber !== '' && ! $lookup['found'],
            'currentOrders' => $currentOrders->map(fn (Order $order) => $this->presentOrder($order, true))->values(),
            'liveUrl' => route('shipping.track.live', array_filter([
                'tracking_number' => $trackingNumber !== '' ? $trackingNumber : null,
            ])),
        ]);
    }

    public function live(Request $request): JsonResponse
    {
        $trackingNumber = trim((string) $request->query('tracking_number', ''));
        $lookup = null;

        if ($trackingNumber !== '') {
            $data = $request->validate([
                'tracking_number' => ['required', 'string', 'alpha_dash', 'max:40'],
            ]);
            $found = $this->findTrackedShipment($data['tracking_number']);
            $lookup = $found['found']
                ? $this->presentLookup($found['shipment'], $found['parcel'], $found['events'])
                : null;
        }

        return response()->json([
            'orders' => $this->currentOrdersFor($request->user())
                ->map(fn (Order $order) => $this->presentOrder($order, true))
                ->values(),
            'lookup' => $lookup,
            'not_found' => $trackingNumber !== '' && $lookup === null,
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

    private function findTrackedShipment(string $trackingNumber): array
    {
        $shipment = Shipment::query()
            ->whereRaw('UPPER(tracking_number) = ?', [Str::upper($trackingNumber)])
            ->with(['checkpoints', 'order'])
            ->first();

        $parcel = Parcel::query()
            ->whereRaw('UPPER(tracking_number) = ?', [Str::upper($trackingNumber)])
            ->with(['order.statusHistories', 'scans'])
            ->first();

        return [
            'shipment' => $shipment,
            'parcel' => $parcel,
            'events' => $this->eventsFor($shipment, $parcel, $shipment?->order ?? $parcel?->order),
            'found' => $shipment !== null || $parcel !== null,
        ];
    }

    private function currentOrdersFor(?User $user): Collection
    {
        if (! $user) {
            return collect();
        }

        return Order::query()
            ->where('buyer_id', $user->id)
            ->whereNotIn('status', [
                OrderStatus::Completed,
                OrderStatus::Cancelled,
                OrderStatus::Returned,
            ])
            ->with([
                'seller.sellerProfile',
                'shipment.checkpoints',
                'parcel.scans',
                'statusHistories',
            ])
            ->latest('placed_at')
            ->limit(8)
            ->get();
    }

    private function presentOrder(Order $order, bool $includePrivateLinks = false): array
    {
        $shipment = $order->shipment;
        $parcel = $order->parcel;
        $events = $this->presentEvents($this->eventsFor($shipment, $parcel, $order));
        $currentStep = $this->currentStep($shipment, $parcel, $order);

        return [
            'id' => $order->id,
            'order_number' => $order->order_number,
            'shop' => $order->seller?->sellerProfile?->business_name ?: ($order->seller?->name ?? 'JEAP seller'),
            'status' => $this->statusLabel($shipment, $parcel, $order),
            'tracking_number' => $shipment?->tracking_number ?? $parcel?->tracking_number,
            'current_step' => $currentStep,
            'steps' => $this->stepStates($currentStep),
            'events' => $events,
            'href' => $includePrivateLinks ? route('buyer.orders.track', $order) : null,
        ];
    }

    private function presentLookup(?Shipment $shipment, ?Parcel $parcel, Collection $events): array
    {
        $order = $shipment?->order ?? $parcel?->order;
        $currentStep = $this->currentStep($shipment, $parcel, $order);

        return [
            'tracking_number' => $shipment?->tracking_number ?? $parcel?->tracking_number,
            'status' => $this->statusLabel($shipment, $parcel, $order),
            'current_step' => $currentStep,
            'steps' => $this->stepStates($currentStep),
            'events' => $this->presentEvents($events),
        ];
    }

    private function eventsFor(?Shipment $shipment, ?Parcel $parcel, ?Order $order): Collection
    {
        if ($shipment) {
            return $shipment->checkpoints->sortBy('scanned_at')->values()->map(fn ($checkpoint) => [
                'label' => $checkpoint->title,
                'at' => $checkpoint->scanned_at,
                'sort_at' => $checkpoint->scanned_at?->timestamp ?? 0,
            ]);
        }

        if (! $parcel?->order && ! $order) {
            return collect();
        }

        $source = $parcel?->order ?? $order;

        return $source->statusHistories->map(fn ($history) => [
            'label' => str($history->to_status?->value ?? 'Order update')->replace('_', ' ')->title()->toString(),
            'at' => $history->created_at,
            'sort_at' => $history->created_at?->timestamp ?? 0,
        ])->concat(($parcel?->scans ?? collect())->map(fn ($scan) => [
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

    private function presentEvents(Collection $events): array
    {
        return $events->map(fn (array $event) => [
            'label' => $event['label'],
            'at' => $event['at']?->timezone(config('app.timezone'))->format('M j, Y · g:i A') ?? 'Time unavailable',
            'iso' => $event['at']?->toIso8601String(),
        ])->values()->all();
    }

    private function currentStep(?Shipment $shipment, ?Parcel $parcel, ?Order $order): int
    {
        $steps = OrderStatus::shopperSteps();
        $currentStep = 0;

        if ($shipment) {
            return match ($shipment->progress_bar_step) {
                0 => $shipment->status === ShipmentStatus::OrderPlaced ? 0 : 1,
                1 => 2,
                2 => 3,
                3 => 4,
                default => 0,
            };
        }

        $status = $parcel?->status ?? $order?->status;
        if (! $status) {
            return 0;
        }

        foreach ($steps as $index => $step) {
            if (in_array($status, $step['match'], true)) {
                $currentStep = $index;
            }
        }

        if (in_array($status, [OrderStatus::Delivered, OrderStatus::Completed], true)) {
            return count($steps) - 1;
        }

        return $currentStep;
    }

    private function stepStates(int $currentStep): array
    {
        return collect(OrderStatus::shopperSteps())->map(fn (array $step, int $index) => [
            'label' => $step['label'],
            'state' => $index < $currentStep ? 'complete' : ($index === $currentStep ? 'current' : ''),
            'mark' => $index < $currentStep ? '✓' : (string) ($index + 1),
        ])->values()->all();
    }

    private function statusLabel(?Shipment $shipment, ?Parcel $parcel, ?Order $order): string
    {
        if ($shipment?->status) {
            return $shipment->status->label();
        }

        $status = $parcel?->status ?? $order?->status;

        return str(($status?->value ?? 'unknown'))->replace('_', ' ')->title()->toString();
    }
}
