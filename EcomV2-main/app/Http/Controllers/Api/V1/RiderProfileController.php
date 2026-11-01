<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\CourierProfile;
use App\Models\KycDocument;
use App\Models\LogisticsProfile;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class RiderProfileController extends Controller
{
    /**
     * Get rider's assigned fleet details.
     */
    public function fleet(Request $request): JsonResponse
    {
        $user = $request->user();
        $courier = $user->courierProfile;
        $hub = $courier?->logisticsProfile;

        // If not directly linked to a hub, fallback to default primary hub
        if (!$hub) {
            $hub = LogisticsProfile::first();
        }

        $hubName = $hub?->hub_business_name ?? 'JEAP Central Logistics Fleet';
        $hubCode = $hub?->hub_code ?? 'FLEET-LAG-01';

        $totalRiders = CourierProfile::query()
            ->when($hub, fn ($q) => $q->where('logistics_profile_id', $hub->id))
            ->count();
        if ($totalRiders === 0) {
            $totalRiders = CourierProfile::count();
        }

        return response()->json([
            'fleet_name' => $hubName,
            'fleet_code' => $hubCode,
            'fleet_manager' => $hub?->user ? trim($hub->user->first_name . ' ' . $hub->user->last_name) : 'Fleet Operations Team',
            'contact_phone' => $hub?->user?->phone ?? '0917-123-4567',
            'station_address' => 'Santa Cruz Dispatch Center, Laguna, Philippines',
            'operating_hours' => 'Mon - Sat: 6:00 AM - 8:00 PM',
            'active_riders_count' => max(1, $totalRiders),
            'rider_status' => $courier?->is_online ? 'Active / On-Duty' : 'Off-Duty',
            'assigned_zone' => 'Laguna Province - District 1 & 2',
        ]);
    }

    /**
     * Get vehicle information.
     */
    public function getVehicle(Request $request): JsonResponse
    {
        $user = $request->user();
        $courier = $user->courierProfile;

        return response()->json([
            'vehicle_type' => $courier?->vehicle_type ?? 'Motorcycle',
            'plate_number' => $courier?->plate_number ?? 'ND-4110',
            'license_number' => $courier?->license_number ?? 'N01-23-456789',
            'license_expires_at' => $courier?->license_expires_at?->format('Y-m-d') ?? '2027-12-31',
            'is_online' => (bool) ($courier?->is_online ?? true),
            'model_name' => 'Yamaha NMAX 155',
            'fuel_type' => 'Gasoline',
            'max_weight_capacity_kg' => 25.0,
        ]);
    }

    /**
     * Update vehicle information.
     */
    public function updateVehicle(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'vehicle_type' => ['nullable', 'string', 'max:50'],
            'plate_number' => ['nullable', 'string', 'max:20'],
            'license_number' => ['nullable', 'string', 'max:30'],
            'license_expires_at' => ['nullable', 'date'],
            'is_online' => ['nullable', 'boolean'],
        ]);

        $user = $request->user();
        $courier = $user->courierProfile;

        if (!$courier) {
            $courier = CourierProfile::create([
                'user_id' => $user->id,
                'vehicle_type' => $validated['vehicle_type'] ?? 'Motorcycle',
                'plate_number' => $validated['plate_number'] ?? null,
                'license_number' => $validated['license_number'] ?? null,
                'license_expires_at' => $validated['license_expires_at'] ?? null,
                'is_online' => $validated['is_online'] ?? true,
            ]);
        } else {
            $courier->update(array_filter($validated, fn ($v) => $v !== null));
        }

        return response()->json([
            'message' => 'Vehicle details updated successfully.',
            'vehicle' => [
                'vehicle_type' => $courier->vehicle_type,
                'plate_number' => $courier->plate_number,
                'license_number' => $courier->license_number,
                'license_expires_at' => $courier->license_expires_at?->format('Y-m-d'),
                'is_online' => (bool) $courier->is_online,
            ],
        ]);
    }

    /**
     * List rider documents with review status.
     */
    public function getDocuments(Request $request): JsonResponse
    {
        $user = $request->user();
        $dbDocs = KycDocument::query()->where('user_id', $user->id)->get()->keyBy('type');

        $docTypes = [
            'drivers_license' => "Professional Driver's License",
            'or_cr' => 'Vehicle Registration (OR/CR)',
            'clearance' => 'NBI / Police Clearance',
            'drug_test' => 'Drug Test Certificate',
        ];

        $documents = [];
        foreach ($docTypes as $key => $title) {
            $doc = $dbDocs->get($key);
            $documents[] = [
                'type' => $key,
                'title' => $title,
                'status' => $doc ? strtolower($doc->review_status->value ?? (string) $doc->review_status) : 'not_submitted',
                'file_name' => $doc ? basename($doc->file_path) : null,
                'submitted_at' => $doc?->created_at?->toIso8601String(),
                'reviewed_at' => $doc?->reviewed_at?->toIso8601String(),
                'rejection_reason' => $doc?->notes,
                'requires_action' => !$doc || in_array(strtolower($doc->review_status->value ?? (string) $doc->review_status), ['rejected', 'expired']),
            ];
        }

        return response()->json([
            'documents' => $documents,
            'summary' => [
                'total' => count($docTypes),
                'approved' => collect($documents)->where('status', 'approved')->count(),
                'pending' => collect($documents)->where('status', 'pending_review')->count(),
                'action_needed' => collect($documents)->where('requires_action', true)->count(),
            ],
        ]);
    }

    /**
     * Secure upload for rider verification document.
     */
    public function uploadDocument(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'type' => ['required', 'string', 'in:drivers_license,or_cr,clearance,drug_test'],
            'document' => ['required', 'file', 'mimes:jpg,jpeg,png,pdf', 'max:5120'],
        ]);

        $user = $request->user();
        $type = $validated['type'];
        $file = $request->file('document');

        $path = $file->store("rider_documents/{$user->id}", 'local');

        $kycDoc = KycDocument::updateOrCreate(
            ['user_id' => $user->id, 'type' => $type],
            [
                'file_path' => $path,
                'review_status' => 'pending_review',
                'notes' => null,
                'reviewed_by' => null,
                'reviewed_at' => null,
            ]
        );

        return response()->json([
            'message' => 'Document uploaded successfully and queued for verification.',
            'document' => [
                'type' => $type,
                'status' => 'pending_review',
                'file_name' => basename($path),
                'submitted_at' => $kycDoc->updated_at?->toIso8601String(),
            ],
        ]);
    }
}
