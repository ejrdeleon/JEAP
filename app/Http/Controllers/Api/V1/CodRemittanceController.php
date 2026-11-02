<?php

namespace App\Http\Controllers\Api\V1;

use App\Enums\OrderStatus;
use App\Http\Controllers\Controller;
use App\Models\CodRemittance;
use App\Models\DeliveryAssignment;
use App\Models\Order;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class CodRemittanceController extends Controller
{
    // Rider: list unremitted delivered orders
    public function pending(Request $request): JsonResponse
    {
        $orders = $this->pendingOrders($request->user())->map(fn (Order $o) => [
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
            'order_ids' => ['nullable', 'array', 'min:1'],
            'order_ids.*' => ['integer'],
            'amount' => ['nullable', 'numeric', 'min:0.01'],
            'notes' => ['nullable', 'string', 'max:500'],
        ]);

        $pending = $this->pendingOrders($request->user());
        $orders = ! empty($data['order_ids'])
            ? $pending->whereIn('id', $data['order_ids'])->values()
            : $pending->values();

        if ($orders->isEmpty() || (! empty($data['order_ids']) && $orders->count() !== count($data['order_ids']))) {
            return response()->json(['message' => 'One or more orders are not eligible for remittance.'], 422);
        }

        if (isset($data['amount']) && abs((float) $data['amount'] - (float) $orders->sum('total')) > 0.009) {
            return response()->json(['message' => 'Remittance amount does not match the selected COD total.'], 422);
        }

        $remittance = DB::transaction(function () use ($request, $orders, $data): CodRemittance {
            $total = $orders->sum('total');
            $remittance = CodRemittance::query()->create([
                'courier_id' => $request->user()->id,
                'logistics_id' => $request->user()->id, // will be confirmed by logistics
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
            ->when(! $request->user()->hasRole('admin'), fn ($q) => $q->where('logistics_id', $request->user()->id))
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
        if ($remittance->status !== 'pending') {
            return response()->json(['message' => 'Already confirmed.'], 422);
        }

        $remittance->update([
            'status' => 'confirmed',
            'logistics_id' => $request->user()->id,
            'remitted_at' => now(),
        ]);

        return response()->json(['message' => 'Remittance confirmed.']);
    }

    private function pendingOrders(User $user): Collection
    {
        $remittedOrderIds = CodRemittance::query()
            ->where('courier_id', $user->id)
            ->join('cod_remittance_orders', 'cod_remittances.id', '=', 'cod_remittance_orders.remittance_id')
            ->pluck('cod_remittance_orders.order_id');

        return DeliveryAssignment::query()
            ->where('courier_id', $user->id)
            ->where('status', 'delivered')
            ->with(['parcel.order'])
            ->get()
            ->map(fn ($a) => $a->parcel?->order)
            ->filter(fn ($o) => $o && $o->status === OrderStatus::Completed && ! $remittedOrderIds->contains($o->id))
            ->values();
    }
}
