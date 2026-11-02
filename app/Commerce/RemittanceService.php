<?php

namespace App\Commerce;

use App\Enums\OrderStatus;
use App\Models\CodRemittance;
use App\Models\Commission;
use App\Models\DeliveryAssignment;
use App\Models\Order;
use App\Models\User;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class RemittanceService
{
    public function pendingOrders(User $courier): Collection
    {
        $remittedIds = CodRemittance::query()
            ->where('courier_id', $courier->id)
            ->whereHas('orders')
            ->with('orders:id')
            ->get()
            ->pluck('orders')
            ->flatten()
            ->pluck('id');

        return DeliveryAssignment::query()
            ->where('courier_id', $courier->id)
            ->where('status', 'delivered')
            ->with(['parcel.order.commission'])
            ->get()
            ->map(fn (DeliveryAssignment $assignment) => $assignment->parcel?->order)
            ->filter(fn ($order) => $order
                && $order->status === OrderStatus::Completed
                && ! $remittedIds->contains($order->id))
            ->values();
    }

    /**
     * @param  array<int, int>  $orderIds
     */
    public function submit(User $courier, array $orderIds, ?string $notes = null): CodRemittance
    {
        $pending = $this->pendingOrders($courier);
        $selected = $pending->whereIn('id', $orderIds);
        if ($selected->count() !== count($orderIds) || $selected->isEmpty()) {
            throw ValidationException::withMessages(['orders' => 'One or more orders are not eligible for remittance.']);
        }

        $courier->loadMissing('courierProfile.logisticsProfile');
        $logisticsUserId = $courier->courierProfile?->logisticsProfile?->user_id;
        if (! $logisticsUserId) {
            throw ValidationException::withMessages(['orders' => 'This rider is not linked to a sorting center.']);
        }

        return DB::transaction(function () use ($courier, $selected, $notes, $logisticsUserId): CodRemittance {
            $remittance = CodRemittance::query()->create([
                'courier_id' => $courier->id,
                'logistics_id' => $logisticsUserId,
                'amount' => $selected->sum(fn (Order $order) => (float) $order->total),
                'status' => 'pending',
                'notes' => $notes,
            ]);
            foreach ($selected as $order) {
                $remittance->orders()->attach($order->id, ['cod_amount' => $order->total]);
            }

            return $remittance;
        });
    }

    public function confirm(User $logistics, CodRemittance $remittance): CodRemittance
    {
        if ($remittance->status !== 'pending') {
            throw ValidationException::withMessages(['remittance' => 'This remittance has already been confirmed.']);
        }

        return DB::transaction(function () use ($logistics, $remittance): CodRemittance {
            $locked = CodRemittance::query()->whereKey($remittance->id)->lockForUpdate()->firstOrFail();
            $locked->update([
                'status' => 'confirmed',
                'logistics_id' => $logistics->id,
                'remitted_at' => now(),
            ]);
            $orderIds = $locked->orders()->pluck('orders.id');
            Commission::query()->whereIn('order_id', $orderIds)->where('status', 'pending')->update([
                'status' => 'paid',
                'paid_at' => now(),
            ]);

            return $locked->refresh();
        });
    }
}
