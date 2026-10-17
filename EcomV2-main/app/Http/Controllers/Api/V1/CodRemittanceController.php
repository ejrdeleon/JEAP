<?php

namespace App\Http\Controllers\Api\V1;

use App\Enums\OrderStatus;
use App\Http\Controllers\Controller;
use App\Models\CodRemittance;
use App\Models\DeliveryAssignment;
use App\Models\Order;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CodRemittanceController extends Controller
{
    // Rider: list unremitted delivered orders
    public function pending(Request $request): JsonResponse
    {
        $remittedOrderIds = CodRemittance::query()
            ->join('cod_remittance_orders', 'cod_remittances.id', '=', 'cod_remittance_orders.remittance_id')
            ->pluck('cod_remittance_orders.order_id');

        $orders = DeliveryAssignment::query()
            ->where('courier_id', $request->user()->id)
            ->where('status', 'delivered')
            ->with(['parcel.order'])
            ->get()
            ->map(fn ($a) => $a->parcel?->order)
            ->filter(fn ($o) => $o && $o->status === OrderStatus::Completed && ! $remittedOrderIds->contains($o->id))
            ->map(fn ($o) => [
                'order_number' => $o->order_number,
                'order_id' => $o->id,
                'cod_amount' => (float) $o->total,
            ])->values();

        return response()->json(['orders' => $orders, 'total' => $orders->sum('cod_amount')]);
    }

    // Rider: submit remittance to logistics
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'order_ids' => ['required', 'array', 'min:1'],
            'order_ids.*' => ['integer', 'distinct'],
            'notes' => ['nullable', 'string', 'max:500'],
        ]);

        $orderIds = collect($data['order_ids'])->unique()->values();
        $remittance = DB::transaction(function () use ($request, $orderIds, $data): CodRemittance {
            $orders = Order::query()
                ->whereIn('id', $orderIds)
                ->where('status', OrderStatus::Completed)
                ->lockForUpdate()
                ->get();
            abort_unless($orders->count() === $orderIds->count(), 422, 'One or more orders are not eligible for remittance.');

            $deliveredOrderIds = DeliveryAssignment::query()
                ->where('courier_id', $request->user()->id)
                ->where('status', 'delivered')
                ->whereHas('parcel.order', fn ($query) => $query
                    ->whereIn('orders.id', $orderIds)
                    ->where('orders.status', OrderStatus::Completed->value))
                ->with('parcel')
                ->get()
                ->pluck('parcel.order_id')
                ->unique();
            abort_unless($orderIds->diff($deliveredOrderIds)->isEmpty(), 422, 'One or more orders are not eligible for remittance.');
            abort_if(
                DB::table('cod_remittance_orders')->whereIn('order_id', $orderIds)->exists(),
                422,
                'One or more orders have already been submitted for remittance.',
            );

            $total = $orders->sum('total');
            $remittance = CodRemittance::query()->create([
                'courier_id' => $request->user()->id,
                'logistics_id' => null,
                'amount' => $total,
                'status' => 'pending',
                'notes' => $data['notes'] ?? null,
            ]);

            foreach ($orders as $order) {
                $remittance->orders()->attach($order->id, ['cod_amount' => $order->total]);
            }

            return $remittance;
        });

        return response()->json(['message' => 'Remittance submitted.', 'remittance_id' => $remittance->id], 201);
    }

    // Logistics: list pending remittances
    public function index(Request $request): JsonResponse
    {
        $remittances = CodRemittance::query()
            ->with(['courier', 'orders'])
            ->when($request->user()->hasRole('logistics'), fn ($q) => $q->where(fn ($query) => $query
                ->whereNull('logistics_id')
                ->orWhere('logistics_id', $request->user()->id)))
            ->latest()
            ->get()
            ->map(fn ($r) => [
                'id' => $r->id,
                'courier' => $r->courier?->name,
                'amount' => (float) $r->amount,
                'status' => $r->status,
                'remitted_at' => $r->remitted_at?->toISOString(),
                'order_count' => $r->orders->count(),
            ]);

        return response()->json(['remittances' => $remittances]);
    }

    // Logistics: confirm receipt of cash
    public function confirm(Request $request, CodRemittance $remittance): JsonResponse
    {
        DB::transaction(function () use ($request, $remittance): void {
            $remittance = CodRemittance::query()->whereKey($remittance->id)->lockForUpdate()->firstOrFail();
            abort_unless($remittance->status === 'pending', 422, 'Already confirmed.');
            abort_if(
                $request->user()->hasRole('logistics')
                    && $remittance->logistics_id !== null
                    && $remittance->logistics_id !== $request->user()->id,
                404,
            );

            $remittance->update([
                'status' => 'confirmed',
                'logistics_id' => $request->user()->id,
                'remitted_at' => now(),
            ]);
        });

        return response()->json(['message' => 'Remittance confirmed.']);
    }
}
