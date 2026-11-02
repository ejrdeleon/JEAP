<?php

namespace App\Commerce;

use App\Enums\OrderStatus;
use App\Enums\PaymentStatus;
use App\Models\Order;
use App\Models\Payment;
use App\Models\ReturnRequest;
use App\Models\User;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class ReturnService
{
    /**
     * @param  array<int, UploadedFile>  $evidence
     */
    public function request(User $buyer, Order $order, string $reason, ?string $description, array $evidence = []): ReturnRequest
    {
        abort_unless($order->buyer_id === $buyer->id, 404);
        abort_unless(in_array($order->status, [OrderStatus::Delivered, OrderStatus::Completed], true), 409, 'Only delivered orders can be returned.');

        if ($order->returnRequest()->exists()) {
            throw ValidationException::withMessages(['order' => 'A return request already exists for this order.']);
        }

        $paths = [];
        foreach ($evidence as $file) {
            $paths[] = $file->store('returns/'.$order->id, 'local');
        }

        return ReturnRequest::query()->create([
            'order_id' => $order->id,
            'buyer_id' => $buyer->id,
            'seller_id' => $order->seller_id,
            'reason' => $reason,
            'description' => $description,
            'evidence_paths' => $paths ?: null,
            'status' => 'pending',
        ]);
    }

    public function decide(ReturnRequest $returnRequest, string $decision, ?string $notes = null): ReturnRequest
    {
        if ($returnRequest->status !== 'pending') {
            throw ValidationException::withMessages(['return' => 'This return request has already been resolved.']);
        }

        return DB::transaction(function () use ($returnRequest, $decision, $notes): ReturnRequest {
            $locked = ReturnRequest::query()->whereKey($returnRequest->id)->lockForUpdate()->firstOrFail();
            $locked->update([
                'status' => $decision,
                'admin_notes' => $notes,
                'resolved_at' => now(),
            ]);

            if ($decision === 'approved') {
                $order = Order::query()->whereKey($locked->order_id)->lockForUpdate()->firstOrFail();
                $order->update(['status' => OrderStatus::Returned]);
                Payment::query()->create([
                    'checkout_group_id' => $order->checkout_group_id,
                    'order_id' => $order->id,
                    'return_request_id' => $locked->id,
                    'gateway' => 'cod',
                    'method' => 'refund',
                    'amount' => $order->total,
                    'status' => PaymentStatus::Refunded,
                    'gateway_reference' => 'REFUND-'.$order->order_number,
                ]);
                $order->commission()?->update(['status' => 'void']);
            }

            return $locked->refresh();
        });
    }
}
