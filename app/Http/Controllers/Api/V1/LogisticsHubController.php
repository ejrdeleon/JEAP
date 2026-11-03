<?php

namespace App\Http\Controllers\Api\V1;

use App\Commerce\ShipmentWorkflow;
use App\Enums\OrderStatus;
use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Parcel;
use App\Models\ParcelScan;
use App\Models\Shipment;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use Symfony\Component\HttpKernel\Exception\ConflictHttpException;
use Throwable;

class LogisticsHubController extends Controller
{
    public function dashboard(Request $request): JsonResponse
    {
        $counts = Parcel::query()
            ->selectRaw('status, COUNT(*) as aggregate')
            ->groupBy('status')
            ->pluck('aggregate', 'status');

        $profile = $request->user()->logisticsProfile;

        return response()->json([
            'success' => true,
            'data' => [
                'hub_name' => $profile?->hub_business_name ?? config('jeap.courier_name', 'JEAP Dash'),
                'hub_code' => $profile?->hub_code ?? 'HUB',
                'stats' => [
                    'incoming' => $this->countStatuses($counts, [OrderStatus::ReadyForPickup, OrderStatus::PickedUp]),
                    'received' => $this->countStatuses($counts, [OrderStatus::AtSortingCenter]),
                    'awaiting_sorting' => $this->countStatuses($counts, [OrderStatus::AtSortingCenter]),
                    'ready_for_dispatch' => $this->countStatuses($counts, [OrderStatus::Sorted]),
                    'outgoing' => $this->countStatuses($counts, [OrderStatus::AssignedToRider, OrderStatus::OutForDelivery]),
                ],
                'recent_activity' => $this->recentActivity(),
            ],
        ]);
    }

    public function show(string $identifier): JsonResponse
    {
        $parcel = $this->findParcel($identifier);

        return response()->json([
            'success' => true,
            'data' => $this->parcelPayload($parcel),
        ]);
    }

    public function scan(Request $request, ShipmentWorkflow $workflow): JsonResponse
    {
        $data = $request->validate([
            'identifier' => ['required', 'string', 'max:64'],
            'action' => ['required', Rule::in(['receive', 'sort', 'dispatch', 'transfer'])],
            'destination_hub' => ['nullable', 'string', 'max:120'],
            'notes' => ['nullable', 'string', 'max:500'],
        ]);

        if ($data['action'] === 'transfer') {
            return response()->json([
                'success' => false,
                'message' => 'Hub transfer is not a status skip. Receive, sort, then dispatch the parcel in order.',
            ], 409);
        }

        $next = match ($data['action']) {
            'receive' => OrderStatus::AtSortingCenter,
            'sort' => OrderStatus::Sorted,
            default => OrderStatus::AssignedToRider,
        };
        $notes = ($data['notes'] ?? null) ?: match ($data['action']) {
            'receive' => 'Parcel received at the sorting center.',
            'sort' => 'Parcel sorted and ready for last-mile delivery.',
            default => 'Parcel dispatched to the delivery fleet.',
        };

        try {
            $parcel = DB::transaction(function () use ($data, $next, $notes, $request, $workflow): Parcel {
                $parcel = $this->findParcel($data['identifier'], lock: true);
                $order = Order::query()->whereKey($parcel->order_id)->lockForUpdate()->firstOrFail();
                $workflow->transition($order, $parcel, $next, $request->user(), $notes);
                $parcel->update(['current_hub_id' => $request->user()->id]);
                ParcelScan::query()->create([
                    'parcel_id' => $parcel->id,
                    'scanned_by' => $request->user()->id,
                    'location_type' => 'hub',
                    'location_id' => $request->user()->id,
                    'notes' => $notes,
                ]);

                return $parcel->fresh(['order.buyer', 'order.items', 'order.shipment']);
            });
        } catch (ConflictHttpException $exception) {
            return response()->json([
                'success' => false,
                'message' => $exception->getMessage(),
            ], 409);
        } catch (Throwable $exception) {
            report($exception);

            return response()->json([
                'success' => false,
                'message' => 'Unable to process this parcel scan.',
            ], 422);
        }

        return response()->json([
            'success' => true,
            'message' => 'Parcel scanned successfully.',
            'data' => $this->parcelPayload($parcel),
        ]);
    }

    public function auditLog(): JsonResponse
    {
        return response()->json([
            'success' => true,
            'data' => $this->recentActivity(50),
        ]);
    }

    private function findParcel(string $identifier, bool $lock = false): Parcel
    {
        $query = Parcel::query()
            ->with(['order.buyer', 'order.items', 'order.shipment'])
            ->where(function (Builder $q) use ($identifier): void {
                $q->where('tracking_number', $identifier)
                    ->orWhereHas('order', fn (Builder $order) => $order->where('order_number', $identifier))
                    ->orWhereHas('order.shipment', fn (Builder $shipment) => $shipment->where('tracking_number', $identifier));
            });

        if ($lock) {
            $query->lockForUpdate();
        }

        $parcel = $query->first();
        if ($parcel) {
            return $parcel;
        }

        $shipment = Shipment::query()->where('tracking_number', $identifier)->first();
        abort_unless($shipment?->order?->parcel, 404, 'Parcel not found.');

        return $shipment->order->parcel->load(['order.buyer', 'order.items', 'order.shipment']);
    }

    private function parcelPayload(Parcel $parcel): array
    {
        $order = $parcel->order;
        $address = $order?->shipping_address_snapshot ?? [];
        $status = $parcel->status ?? $order?->status;

        return [
            'tracking_number' => $parcel->tracking_number,
            'order_number' => $order?->order_number,
            'status' => $status instanceof OrderStatus ? $status->value : (string) $status,
            'recipient_name' => $address['recipient_name'] ?? $order?->buyer?->name ?? 'Customer',
            'recipient_phone' => $address['phone'] ?? $order?->buyer?->phone ?? '',
            'destination_address' => implode(', ', array_filter([
                $address['street_line'] ?? null,
                $address['barangay_name'] ?? null,
                $address['city_name'] ?? null,
                $address['province_name'] ?? null,
            ])),
            'origin_hub' => $order?->shipment?->current_hub ?? config('jeap.courier_name', 'JEAP Dash'),
            'items_count' => $order?->items?->sum('quantity') ?? 0,
            'total_amount' => (float) ($order?->total ?? 0),
            'payment_method' => 'COD',
            'created_at' => $parcel->created_at?->toIso8601String(),
            'allowed_actions' => match ($status) {
                OrderStatus::PickedUp => ['receive'],
                OrderStatus::AtSortingCenter => ['sort'],
                OrderStatus::Sorted => ['dispatch'],
                default => [],
            },
        ];
    }

    private function recentActivity(int $limit = 20): array
    {
        return ParcelScan::query()
            ->with(['parcel.order', 'scannedBy'])
            ->latest()
            ->limit($limit)
            ->get()
            ->map(fn (ParcelScan $scan) => [
                'tracking_number' => $scan->parcel?->tracking_number,
                'order_number' => $scan->parcel?->order?->order_number,
                'status' => $scan->parcel?->status instanceof OrderStatus
                    ? $scan->parcel->status->value
                    : (string) $scan->parcel?->status,
                'action' => $scan->notes ?: 'Scanned at hub',
                'timestamp' => $scan->created_at?->toIso8601String(),
                'location' => $scan->location_type,
            ])
            ->values()
            ->all();
    }

    private function countStatuses($counts, array $statuses): int
    {
        return collect($statuses)->sum(fn (OrderStatus $status) => (int) ($counts[$status->value] ?? 0));
    }
}
