<?php

namespace App\Services;

use App\Enums\OrderStatus;
use App\Enums\ShipmentStatus;
use App\Events\ShipmentMilestoneUpdated;
use App\Models\Order;
use App\Models\Shipment;
use App\Models\ShipmentCheckpoint;
use App\Models\User;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class ShipmentService
{
    public function initializeShipment(Order $order): Shipment
    {
        $existing = $order->shipment;
        if ($existing) {
            return $existing;
        }

        return DB::transaction(function () use ($order): Shipment {
            $locked = Order::query()->whereKey($order->id)->lockForUpdate()->firstOrFail();
            if ($locked->shipment) {
                return $locked->shipment;
            }

            $snapshot = $locked->shipping_address_snapshot ?? [];
            $shipment = Shipment::query()->create([
                'order_id' => $locked->id,
                'tracking_number' => $this->uniqueTrackingNumber(),
                'courier_name' => config('jeap.courier_name', 'JEAP Dash'),
                'status' => ShipmentStatus::OrderPlaced,
                'recipient_name' => $snapshot['recipient_name'] ?? $locked->buyer?->name,
                'estimated_delivery_date' => now()->addDays(3)->toDateString(),
            ]);

            ShipmentCheckpoint::query()->create([
                'shipment_id' => $shipment->id,
                'created_by' => $locked->buyer_id,
                'status' => ShipmentStatus::OrderPlaced,
                'title' => ShipmentStatus::OrderPlaced->defaultTitle(),
                'location' => null,
                'notes' => 'Cash on Delivery order placed with '.config('jeap.courier_name', 'JEAP Dash').'.',
                'scanned_at' => $locked->placed_at ?? now(),
            ]);

            return $shipment->load('checkpoints');
        });
    }

    public function logCheckpoint(Shipment $shipment, array $data, User $actor): ShipmentCheckpoint
    {
        $status = $data['status'] instanceof ShipmentStatus
            ? $data['status']
            : ShipmentStatus::from((string) $data['status']);

        return DB::transaction(function () use ($shipment, $data, $actor, $status): ShipmentCheckpoint {
            $locked = Shipment::query()->whereKey($shipment->id)->lockForUpdate()->firstOrFail();
            $hub = isset($data['location']) ? trim((string) $data['location']) : $locked->current_hub;
            $hub = $hub !== '' ? $hub : null;
            $title = trim((string) ($data['title'] ?? '')) ?: $status->defaultTitle($hub);
            $notes = isset($data['notes']) ? trim((string) $data['notes']) : null;
            $notes = $notes !== '' ? $notes : null;
            $scannedAt = $data['scanned_at'] ?? now();

            if ($status === ShipmentStatus::Delivered) {
                $proof = $data['proof_of_delivery'] ?? null;
                if ($proof instanceof UploadedFile) {
                    $locked->proof_of_delivery = $proof->store('proof_of_delivery', 'public');
                }
                if (! $locked->proof_of_delivery && empty($data['skip_proof'])) {
                    throw ValidationException::withMessages([
                        'proof_of_delivery' => 'Upload a proof-of-delivery photo when marking the parcel delivered.',
                    ]);
                }
                $locked->delivered_at = $locked->delivered_at ?? now();
                if (! empty($data['recipient_name'])) {
                    $locked->recipient_name = trim((string) $data['recipient_name']);
                }
                $order = Order::query()->whereKey($locked->order_id)->lockForUpdate()->firstOrFail();
                if (! in_array($order->status, [OrderStatus::Delivered, OrderStatus::Completed], true)) {
                    $order->update(['status' => OrderStatus::Delivered]);
                }
            }

            if ($status === ShipmentStatus::OutForDelivery) {
                $courierId = isset($data['courier_id']) ? (int) $data['courier_id'] : null;
                if ($courierId) {
                    $locked->courier_id = $courierId;
                } elseif ($actor->hasRole('courier')) {
                    $locked->courier_id = $actor->id;
                }
            }

            if ($status === ShipmentStatus::FailedDelivery) {
                $order = Order::query()->whereKey($locked->order_id)->lockForUpdate()->firstOrFail();
                if ($order->status === OrderStatus::OutForDelivery) {
                    $order->update(['status' => OrderStatus::DeliveryFailed]);
                }
            }

            if ($status === ShipmentStatus::Cancelled) {
                $order = Order::query()->whereKey($locked->order_id)->lockForUpdate()->firstOrFail();
                if (in_array($order->status, [OrderStatus::Placed, OrderStatus::Confirmed, OrderStatus::Preparing], true)) {
                    $order->update(['status' => OrderStatus::Cancelled]);
                }
            }

            $locked->status = $status;
            $locked->current_hub = $hub;
            $locked->save();

            $checkpoint = ShipmentCheckpoint::query()->create([
                'shipment_id' => $locked->id,
                'created_by' => $actor->id,
                'status' => $status,
                'title' => $title,
                'location' => $hub,
                'notes' => $notes,
                'scanned_at' => $scannedAt,
            ]);

            event(new ShipmentMilestoneUpdated($locked->fresh(['order', 'courier', 'checkpoints']), $checkpoint));

            return $checkpoint;
        });
    }

    public function recordOrderMilestone(
        Order $order,
        User $actor,
        ShipmentStatus $status,
        ?string $title = null,
        ?string $location = null,
        ?string $notes = null,
        array $extra = [],
    ): ShipmentCheckpoint {
        $shipment = $this->initializeShipment($order);

        return $this->logCheckpoint($shipment, array_merge([
            'status' => $status,
            'title' => $title,
            'location' => $location,
            'notes' => $notes,
            'scanned_at' => now(),
        ], $extra), $actor);
    }

    private function uniqueTrackingNumber(): string
    {
        do {
            $number = sprintf('JD-%s-%s', now()->format('Ymd'), strtoupper(Str::random(5)));
        } while (Shipment::query()->where('tracking_number', $number)->exists());

        return $number;
    }
}
