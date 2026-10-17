<?php

namespace App\Http\Controllers\Api\V1;

use App\Enums\OrderStatus;
use App\Enums\PaymentStatus;
use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Payment;
use App\Models\ReturnRequest;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class ReturnRequestController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $query = ReturnRequest::query()->with(['order.items', 'buyer', 'seller']);

        if ($user->hasRole('admin')) {
            // admin sees all
        } elseif ($user->hasRole('seller')) {
            $query->where('seller_id', $user->id);
        } else {
            $query->where('buyer_id', $user->id);
        }

        return response()->json(['returns' => $query->latest()->get()->map(fn ($r) => $this->payload($r))]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'order_number' => ['required', 'string'],
            'reason' => ['required', Rule::in(['damaged_item', 'wrong_item', 'not_as_described', 'other'])],
            'description' => ['nullable', 'string', 'max:1000'],
            'evidence' => ['nullable', 'array', 'max:5'],
            'evidence.*' => ['image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
        ]);

        $order = Order::query()
            ->where('buyer_id', $request->user()->id)
            ->where('order_number', $data['order_number'])
            ->whereIn('status', [OrderStatus::Delivered, OrderStatus::Completed])
            ->firstOrFail();

        if ($order->returnRequest()->exists()) {
            return response()->json(['message' => 'A return request already exists for this order.'], 422);
        }

        $evidencePaths = [];
        foreach ($request->file('evidence', []) as $file) {
            $evidencePaths[] = $file->store('returns/'.$order->id, 'local');
        }

        $returnRequest = ReturnRequest::query()->create([
            'order_id' => $order->id,
            'buyer_id' => $request->user()->id,
            'seller_id' => $order->seller_id,
            'reason' => $data['reason'],
            'description' => $data['description'] ?? null,
            'evidence_paths' => $evidencePaths ?: null,
            'status' => 'pending',
        ]);

        return response()->json(['message' => 'Return request submitted.', 'return' => $this->payload($returnRequest)], 201);
    }

    // Admin: approve or reject
    public function decide(Request $request, ReturnRequest $returnRequest): JsonResponse
    {
        $data = $request->validate([
            'decision' => ['required', 'in:approved,rejected'],
            'notes' => ['nullable', 'string', 'max:500'],
        ]);

        if ($returnRequest->status !== 'pending') {
            return response()->json(['message' => 'This return request has already been resolved.'], 422);
        }

        DB::transaction(function () use ($returnRequest, $data): void {
            $returnRequest->update([
                'status' => $data['decision'],
                'admin_notes' => $data['notes'] ?? null,
                'resolved_at' => now(),
            ]);

            if ($data['decision'] === 'approved') {
                $order = $returnRequest->order;
                $order->update(['status' => OrderStatus::Returned]);

                // Issue refund payment record
                Payment::query()->create([
                    'checkout_group_id' => $order->checkout_group_id,
                    'order_id' => $order->id,
                    'return_request_id' => $returnRequest->id,
                    'gateway' => 'cod',
                    'method' => 'refund',
                    'amount' => $order->total,
                    'status' => PaymentStatus::Refunded,
                    'gateway_reference' => 'REFUND-'.$order->order_number,
                ]);

                // Void commission
                $order->commission()?->update(['status' => 'void']);
            }
        });

        return response()->json(['message' => 'Return request '.$data['decision'].'.']);
    }

    private function payload(ReturnRequest $r): array
    {
        return [
            'id' => $r->id,
            'order_number' => $r->order?->order_number,
            'reason' => $r->reason,
            'description' => $r->description,
            'status' => $r->status,
            'admin_notes' => $r->admin_notes,
            'resolved_at' => $r->resolved_at?->toISOString(),
            'created_at' => $r->created_at?->toISOString(),
        ];
    }
}
