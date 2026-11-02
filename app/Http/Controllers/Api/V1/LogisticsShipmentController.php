<?php

namespace App\Http\Controllers\Api\V1;

use App\Commerce\CourierAssignmentService;
use App\Commerce\ShipmentWorkflow;
use App\Http\Controllers\Controller;
use App\Models\Parcel;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LogisticsShipmentController extends Controller
{
    public function assignPickup(Request $request, Parcel $parcel, CourierAssignmentService $assignments): JsonResponse
    {
        $data = $request->validate(['courier_id' => ['required', 'integer', 'exists:users,id']]);
        $assignment = $assignments->assignPickup($parcel, (int) $data['courier_id'], $request->user());

        return response()->json([
            'message' => 'Pickup rider assigned.',
            'assignment' => [
                'id' => $assignment->id,
                'parcel_id' => $assignment->parcel_id,
                'courier_id' => $assignment->courier_id,
                'status' => $assignment->status,
            ],
        ]);
    }

    public function assignDelivery(
        Request $request,
        Parcel $parcel,
        CourierAssignmentService $assignments,
        ShipmentWorkflow $workflow
    ): JsonResponse {
        $data = $request->validate(['courier_id' => ['required', 'integer', 'exists:users,id']]);
        $assignment = $assignments->assignDelivery($parcel, (int) $data['courier_id'], $request->user(), $workflow);

        return response()->json([
            'message' => 'Delivery rider assigned.',
            'assignment' => [
                'id' => $assignment->id,
                'parcel_id' => $assignment->parcel_id,
                'courier_id' => $assignment->courier_id,
                'status' => $assignment->status,
            ],
        ]);
    }
}
