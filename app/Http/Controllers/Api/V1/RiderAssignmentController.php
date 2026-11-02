<?php

namespace App\Http\Controllers\Api\V1;

use App\Commerce\ShipmentWorkflow;
use App\Enums\OrderStatus;
use App\Http\Controllers\Controller;
use App\Models\DeliveryAssignment;
use App\Models\DeliveryAttempt;
use App\Models\Order;
use App\Models\Parcel;
use App\Models\ParcelScan;
use App\Models\PickupAssignment;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Throwable;

class RiderAssignmentController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $pickupAssignments = PickupAssignment::query()->where('courier_id', $request->user()->id)
            ->whereIn('status', ['pending', 'accepted', 'picked_up'])
            ->with(['parcel.order.buyer', 'parcel.order.seller', 'parcel.order.items', 'seller.addresses'])
            ->get();
        $deliveryAssignments = DeliveryAssignment::query()->where('courier_id', $request->user()->id)
            ->whereIn('status', ['pending', 'accepted', 'out_for_delivery', 'delivered', 'failed'])
            ->with(['parcel.order.buyer', 'parcel.order.items'])
            ->latest('assigned_at')->get();

        $assignments = $pickupAssignments->map(fn (PickupAssignment $assignment) => $this->pickupPayload($assignment))
            ->concat($deliveryAssignments->map(fn (DeliveryAssignment $assignment) => $this->deliveryPayload($assignment)))
            ->sortByDesc('assigned_at')->values();

        return response()->json([
            'assignments' => $assignments->map(function (array $assignment): array {
                unset($assignment['assigned_at']);

                return $assignment;
            }),
            'message' => $assignments->isEmpty() ? 'No active assignments.' : null,
        ]);
    }

    public function action(Request $request, string $assignmentKey, string $action, ShipmentWorkflow $workflow): JsonResponse
    {
        [$kind, $id] = $this->parseKey($assignmentKey);
        abort_unless(in_array($action, ['accept', 'scan', 'out-for-delivery', 'deliver', 'fail'], true), 404);

        if ($action === 'deliver') {
            $data = $request->validate([
                'proof' => ['required', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
            ]);
        } elseif ($action === 'fail') {
            $data = $request->validate(['reason' => ['required', 'string', 'min:3', 'max:255']]);
        } else {
            $data = [];
        }

        $storedProofPath = null;
        try {
            $message = DB::transaction(function () use ($request, $kind, $id, $action, $data, $workflow, &$storedProofPath): string {
                $assignment = $kind === 'pickup'
                    ? PickupAssignment::query()->whereKey($id)->lockForUpdate()->firstOrFail()
                    : DeliveryAssignment::query()->whereKey($id)->lockForUpdate()->firstOrFail();
                abort_unless($assignment->courier_id === $request->user()->id, 404);

                $parcel = Parcel::query()->whereKey($assignment->parcel_id)->lockForUpdate()->firstOrFail();
                $order = Order::query()->whereKey($parcel->order_id)->lockForUpdate()->firstOrFail();

                if ($action === 'accept') {
                    abort_unless($assignment->status === 'pending', 409, 'This assignment is no longer waiting for acceptance.');
                    $expectedOrderStatus = $kind === 'pickup' ? OrderStatus::ReadyForPickup : OrderStatus::AssignedToRider;
                    abort_unless($order->status === $expectedOrderStatus, 409, 'The order is no longer at the expected stage.');
                    $assignment->update(['status' => 'accepted']);
                    $this->scan($parcel, $request, 'courier', $request->user()->id, ucfirst($kind).' assignment accepted.');

                    return 'Assignment accepted.';
                }

                if ($action === 'scan') {
                    abort_unless($kind === 'pickup' && $assignment->status === 'accepted', 409, 'Accept the pickup assignment before confirming collection.');
                    $workflow->transition($order, $parcel, OrderStatus::PickedUp, $request->user(), 'Rider collected the parcel from the seller.');
                    $assignment->update(['status' => 'picked_up', 'picked_up_at' => now()]);
                    $this->scan($parcel, $request, 'seller', $assignment->seller_id, 'Parcel picked up from the seller.');

                    return 'Pickup confirmed.';
                }

                if ($action === 'out-for-delivery') {
                    abort_unless($kind === 'delivery' && $assignment->status === 'accepted', 409, 'Accept the delivery assignment before starting the route.');
                    $workflow->transition($order, $parcel, OrderStatus::OutForDelivery, $request->user(), 'Rider started the delivery route.');
                    $assignment->update(['status' => 'out_for_delivery']);
                    $this->scan($parcel, $request, 'courier', $request->user()->id, 'Parcel is out for delivery.');

                    return 'Delivery started.';
                }

                abort_unless($kind === 'delivery' && $assignment->status === 'out_for_delivery', 409, 'This delivery is not in progress.');

                if ($action === 'deliver') {
                    $storedProofPath = $data['proof']->store('proof-of-delivery', 'local');
                    $workflow->transition($order, $parcel, OrderStatus::Delivered, $request->user(), 'Delivery completed; proof of delivery stored.');
                    $assignment->update([
                        'status' => 'delivered',
                        'delivered_at' => now(),
                        'proof_of_delivery_path' => $storedProofPath,
                    ]);
                    $this->scan($parcel, $request, 'buyer', $order->buyer_id, 'Parcel delivered; proof of delivery recorded.');

                    return 'Delivery completed.';
                }

                $reason = $data['reason'];
                $attemptNo = DeliveryAttempt::query()->whereHas('assignment', fn ($query) => $query->where('parcel_id', $parcel->id))->count() + 1;
                $assignment->update(['status' => 'failed']);
                DeliveryAttempt::query()->create([
                    'delivery_assignment_id' => $assignment->id,
                    'attempt_no' => $attemptNo,
                    'failed_reason' => $reason,
                    'notes' => $reason,
                ]);
                $workflow->transition($order, $parcel, OrderStatus::DeliveryFailed, $request->user(), 'Delivery attempt failed: '.$reason);
                $this->scan($parcel, $request, 'buyer', $order->buyer_id, 'Delivery attempt failed: '.$reason);

                return 'Delivery failure recorded. Logistics can assign another attempt.';
            });
        } catch (Throwable $exception) {
            if ($storedProofPath) {
                Storage::disk('local')->delete($storedProofPath);
            }

            throw $exception;
        }

        return response()->json(['message' => $message]);
    }

    private function pickupPayload(PickupAssignment $assignment): array
    {
        $order = $assignment->parcel->order;
        $seller = $assignment->seller;
        $address = $seller->addresses->sortByDesc('is_default')->first();

        return [
            'id' => 'pickup-'.$assignment->id,
            'type' => 'pickup',
            'status' => $assignment->status,
            'assigned_at' => $assignment->assigned_at?->toISOString(),
            'tracking_number' => $assignment->parcel->tracking_number,
            'contact_name' => $seller->name,
            'contact_phone' => $seller->phone ?? '',
            'delivery_address' => $this->addressPayload($address?->toArray()),
            'order' => [
                'order_number' => $order->order_number,
                'buyer' => ['name' => $seller->name, 'phone' => $seller->phone],
                'cod_amount' => 0,
                'items' => $order->items->map(fn ($item) => ['name' => $item->name, 'quantity' => $item->quantity])->values(),
            ],
        ];
    }

    private function deliveryPayload(DeliveryAssignment $assignment): array
    {
        $order = $assignment->parcel->order;
        $buyer = $order->buyer;

        return [
            'id' => 'delivery-'.$assignment->id,
            'type' => 'delivery',
            'status' => $assignment->status,
            'assigned_at' => $assignment->assigned_at?->toISOString(),
            'tracking_number' => $assignment->parcel->tracking_number,
            'contact_name' => $buyer->name,
            'contact_phone' => $buyer->phone ?? '',
            'delivery_address' => $this->addressPayload($order->shipping_address_snapshot),
            'order' => [
                'order_number' => $order->order_number,
                'buyer' => ['name' => $buyer->name, 'phone' => $buyer->phone],
                'cod_amount' => (float) $order->total,
                'items' => $order->items->map(fn ($item) => ['name' => $item->name, 'quantity' => $item->quantity])->values(),
            ],
        ];
    }

    private function addressPayload(?array $address): array
    {
        $address ??= [];
        $formatted = implode(', ', array_filter([
            $address['street_line'] ?? null,
            $address['barangay_name'] ?? null,
            $address['city_name'] ?? null,
            $address['province_name'] ?? null,
            $address['region_name'] ?? null,
            $address['country_name'] ?? null,
            $address['postal_code'] ?? null,
        ]));

        return [
            'formatted_address' => $formatted !== '' ? $formatted : 'Pickup address not provided',
            'latitude' => $address['latitude'] ?? null,
            'longitude' => $address['longitude'] ?? null,
        ];
    }

    private function scan(Parcel $parcel, Request $request, string $locationType, ?int $locationId, string $notes): void
    {
        ParcelScan::query()->create([
            'parcel_id' => $parcel->id,
            'scanned_by' => $request->user()->id,
            'location_type' => $locationType,
            'location_id' => $locationId,
            'notes' => $notes,
        ]);
    }

    private function parseKey(string $key): array
    {
        abort_unless(preg_match('/^(pickup|delivery)-(\d+)$/', $key, $matches) === 1, 404);

        return [$matches[1], (int) $matches[2]];
    }
}
