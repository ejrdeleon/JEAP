<?php

namespace App\Http\Controllers\Api\Dash;

use App\Enums\ShipmentStatus;
use App\Http\Controllers\Controller;
use App\Http\Requests\LogShipmentCheckpointRequest;
use App\Models\DeliveryAssignment;
use App\Models\PickupAssignment;
use App\Models\Shipment;
use App\Services\ShipmentService;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Str;

class ShipmentCheckpointController extends Controller
{
    public function store(LogShipmentCheckpointRequest $request, string $tracking_number, ShipmentService $shipments): JsonResponse
    {
        $shipment = Shipment::query()
            ->whereRaw('UPPER(tracking_number) = ?', [Str::upper($tracking_number)])
            ->firstOrFail();

        $this->authorizeActor($request, $shipment);

        $checkpoint = $shipments->logCheckpoint($shipment, $request->validated(), $request->user());
        $shipment->refresh()->load(['checkpoints.loggedBy', 'courier']);

        return response()->json([
            'message' => 'Checkpoint recorded.',
            'shipment' => [
                'tracking_number' => $shipment->tracking_number,
                'status' => $shipment->status->value,
                'courier_name' => $shipment->courier_name,
                'current_hub' => $shipment->current_hub,
                'progress_step' => $shipment->progress_bar_step,
                'proof_of_delivery_url' => $shipment->proof_of_delivery_url,
                'delivered_at' => $shipment->delivered_at?->toIso8601String(),
            ],
            'checkpoint' => [
                'id' => $checkpoint->id,
                'status' => $checkpoint->status->value,
                'title' => $checkpoint->title,
                'location' => $checkpoint->location,
                'notes' => $checkpoint->notes,
                'scanned_at' => $checkpoint->scanned_at?->toIso8601String(),
                'logged_by' => $checkpoint->loggedBy?->name,
            ],
        ], 201);
    }

    private function authorizeActor(LogShipmentCheckpointRequest $request, Shipment $shipment): void
    {
        $user = $request->user();
        abort_unless($user, 403);

        if ($user->hasAnyRole(['logistics', 'admin', 'super-admin'])) {
            return;
        }

        abort_unless($user->hasRole('courier'), 403);

        $status = $request->validated('status');
        abort_if($status === ShipmentStatus::Cancelled->value, 403);

        $assigned = (int) $shipment->courier_id === (int) $user->id
            || DeliveryAssignment::query()
                ->where('courier_id', $user->id)
                ->whereHas('parcel', fn ($query) => $query->where('order_id', $shipment->order_id))
                ->exists()
            || PickupAssignment::query()
                ->where('courier_id', $user->id)
                ->whereHas('parcel', fn ($query) => $query->where('order_id', $shipment->order_id))
                ->exists();

        abort_unless($assigned, 403, 'You are not assigned to this shipment.');
    }
}
