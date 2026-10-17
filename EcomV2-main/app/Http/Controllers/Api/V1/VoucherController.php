<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Voucher;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class VoucherController extends Controller
{
    public function validate(Request $request): JsonResponse
    {
        $data = $request->validate([
            'code' => ['required', 'string'],
            'subtotal' => ['required', 'numeric', 'min:0'],
        ]);

        $voucher = Voucher::query()
            ->where('code', strtoupper(trim($data['code'])))
            ->first();

        if (! $voucher || ! $voucher->isUsableBy($request->user(), (float) $data['subtotal'])) {
            return response()->json(['message' => 'This voucher is invalid or cannot be applied to your order.'], 422);
        }

        $discount = $voucher->computeDiscount((float) $data['subtotal']);

        return response()->json([
            'voucher_id' => $voucher->id,
            'code' => $voucher->code,
            'type' => $voucher->type,
            'discount' => $discount,
            'description' => $voucher->type === 'percent'
                ? number_format($voucher->value, 0).'% off'
                : '₱'.number_format($voucher->value, 2).' off',
        ]);
    }

    // Seller: list own vouchers
    public function index(Request $request): JsonResponse
    {
        $vouchers = Voucher::query()
            ->where('seller_id', $request->user()->id)
            ->latest()
            ->get();

        return response()->json(['vouchers' => $vouchers]);
    }

    // Seller: create voucher
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'code' => ['required', 'string', 'max:64', 'regex:/^[A-Z0-9_\-]+$/i'],
            'type' => ['required', 'in:percent,fixed'],
            'value' => ['required', 'numeric', 'min:0.01'],
            'min_order' => ['nullable', 'numeric', 'min:0'],
            'max_discount' => ['nullable', 'numeric', 'min:0.01'],
            'usage_limit' => ['nullable', 'integer', 'min:1'],
            'starts_at' => ['nullable', 'date'],
            'expires_at' => ['nullable', 'date', 'after_or_equal:starts_at'],
        ]);

        $data['code'] = strtoupper(trim($data['code']));
        $data['seller_id'] = $request->user()->id;

        if (Voucher::query()->where('code', $data['code'])->exists()) {
            return response()->json(['message' => 'This voucher code is already in use.'], 422);
        }

        $voucher = Voucher::query()->create($data);

        return response()->json(['message' => 'Voucher created.', 'voucher' => $voucher], 201);
    }

    // Seller: toggle active
    public function toggle(Request $request, Voucher $voucher): JsonResponse
    {
        abort_unless($voucher->seller_id === $request->user()->id, 404);
        $voucher->update(['is_active' => ! $voucher->is_active]);

        return response()->json(['message' => 'Voucher updated.', 'is_active' => $voucher->is_active]);
    }

    // Seller: delete
    public function destroy(Request $request, Voucher $voucher): JsonResponse
    {
        abort_unless($voucher->seller_id === $request->user()->id, 404);
        $voucher->delete();

        return response()->json(['message' => 'Voucher deleted.']);
    }
}
