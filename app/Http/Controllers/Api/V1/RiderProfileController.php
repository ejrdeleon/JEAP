<?php

namespace App\Http\Controllers\Api\V1;

use App\Enums\KycDocumentType;
use App\Enums\ReviewStatus;
use App\Enums\UserStatus;
use App\Enums\VehicleType;
use App\Http\Controllers\Controller;
use App\Models\CourierProfile;
use App\Models\KycDocument;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class RiderProfileController extends Controller
{
    public function fleet(Request $request): JsonResponse
    {
        $profile = $this->profile($request);
        $hub = $profile->logisticsProfile;

        return response()->json([
            'fleet_name' => $hub?->hub_business_name ?? config('jeap.courier_name', 'JEAP Dash'),
            'fleet_code' => $hub?->hub_code ?? 'HUB',
            'fleet_manager' => $hub?->user?->name,
            'contact_phone' => $hub?->user?->phone,
            'station_address' => $hub?->addresses()->first()?->street_line,
            'operating_hours' => 'Mon - Sat: 6:00 AM - 8:00 PM',
            'active_riders_count' => $hub
                ? CourierProfile::query()->where('logistics_profile_id', $hub->id)->count()
                : 0,
            'rider_status' => $profile->is_online ? 'Active / On-Duty' : 'Offline',
            'assigned_zone' => $profile->area?->name ?? collect($hub?->service_areas ?? [])->filter()->implode(', '),
        ]);
    }

    public function getVehicle(Request $request): JsonResponse
    {
        $profile = $this->profile($request);

        return response()->json([
            'vehicle_type' => $profile->vehicle_type?->label() ?? $profile->getRawOriginal('vehicle_type'),
            'vehicle_type_value' => $profile->vehicle_type?->value,
            'plate_number' => $profile->plate_number,
            'license_number' => $profile->license_number,
            'license_expires_at' => $profile->license_expires_at?->toDateString(),
            'is_online' => (bool) $profile->is_online,
            'model_name' => $profile->vehicle_type?->label(),
        ]);
    }

    public function updateVehicle(Request $request): JsonResponse
    {
        $profile = $this->profile($request);
        $request->merge([
            'vehicle_type' => VehicleType::fromStored($request->input('vehicle_type'))?->value ?? $request->input('vehicle_type'),
        ]);
        $data = $request->validate([
            'vehicle_type' => ['required', Rule::in(VehicleType::values())],
            'plate_number' => ['required', 'string', 'max:20', Rule::unique('courier_profiles', 'plate_number')->ignore($profile->id)],
            'license_number' => ['required', 'string', 'max:16', Rule::unique('courier_profiles', 'license_number')->ignore($profile->id)],
            'is_online' => ['nullable', 'boolean'],
        ]);

        if (! empty($data['is_online']) && $profile->license_expires_at?->lt(today())) {
            return response()->json(['message' => 'Your driving license has expired. Contact your logistics company before going online.'], 422);
        }

        $profile->update($data);

        return response()->json(['message' => 'Vehicle information saved.', 'vehicle' => $this->getVehicle($request)->getData(true)]);
    }

    public function getDocuments(Request $request): JsonResponse
    {
        $docs = KycDocument::query()->where('user_id', $request->user()->id)->get()->keyBy(fn (KycDocument $doc) => $doc->type->value);
        $types = [
            KycDocumentType::DriversLicense->value => "Professional Driver's License",
            'or_cr' => 'Vehicle Registration (OR/CR)',
            KycDocumentType::Id->value => 'Government ID',
        ];

        $documents = collect($types)->map(function (string $title, string $type) use ($docs) {
            $doc = $docs->get($type)
                ?? ($type === 'or_cr' ? $docs->get(KycDocumentType::VehicleRegistration->value) : null);
            $status = $doc?->review_status?->value ?? 'not_submitted';

            return [
                'type' => $type,
                'title' => $title,
                'status' => $status === ReviewStatus::Pending->value ? 'pending_review' : $status,
                'file_name' => $doc?->file_path ? basename($doc->file_path) : null,
                'submitted_at' => $doc?->created_at?->toIso8601String(),
                'reviewed_at' => $doc?->reviewed_at?->toIso8601String(),
                'rejection_reason' => $doc?->review_status === ReviewStatus::Rejected ? $doc->notes : null,
                'requires_action' => $doc === null || $doc->review_status === ReviewStatus::Rejected,
            ];
        })->values();

        return response()->json([
            'documents' => $documents,
            'summary' => [
                'total' => $documents->count(),
                'approved' => $documents->where('status', 'approved')->count(),
                'pending' => $documents->where('status', 'pending_review')->count(),
                'action_needed' => $documents->where('requires_action', true)->count(),
            ],
        ]);
    }

    public function uploadDocument(Request $request): JsonResponse
    {
        $data = $request->validate([
            'type' => ['required', 'string', Rule::in(['drivers_license', 'vehicle_registration', 'or_cr', 'id'])],
            'document' => ['required', 'file', 'mimes:jpg,jpeg,png,pdf', 'max:5120'],
        ]);

        $type = match ($data['type']) {
            'or_cr' => KycDocumentType::VehicleRegistration,
            'id' => KycDocumentType::Id,
            default => KycDocumentType::from($data['type']),
        };

        $path = $request->file('document')->store('kyc/'.$request->user()->id, 'local');
        $doc = KycDocument::query()->updateOrCreate(
            ['user_id' => $request->user()->id, 'type' => $type],
            [
                'file_path' => $path,
                'review_status' => ReviewStatus::Pending,
                'notes' => null,
                'reviewed_by' => null,
                'reviewed_at' => null,
            ]
        );

        return response()->json([
            'message' => 'Document uploaded and queued for verification.',
            'document' => [
                'type' => $type->value,
                'status' => 'pending_review',
                'file_name' => basename($path),
                'submitted_at' => $doc->updated_at?->toIso8601String(),
            ],
        ]);
    }

    private function profile(Request $request): CourierProfile
    {
        abort_unless($request->user()->status === UserStatus::Active, 403);

        return $request->user()->courierProfile()->with(['logisticsProfile.user', 'logisticsProfile.addresses', 'area'])->firstOrFail();
    }
}
