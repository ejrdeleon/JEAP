<?php

namespace App\Http\Controllers\Buyer;

use App\Commerce\ReturnService;
use App\Enums\OrderStatus;
use App\Http\Controllers\Controller;
use App\Models\Complaint;
use App\Models\Order;
use App\Models\Review;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class AfterSaleController extends Controller
{
    public function storeReturn(Request $request, Order $order, ReturnService $returns): RedirectResponse
    {
        abort_unless($order->buyer_id === $request->user()->id, 404);
        $data = $request->validate([
            'reason' => ['required', Rule::in(['damaged_item', 'wrong_item', 'not_as_described', 'other'])],
            'description' => ['nullable', 'string', 'max:1000'],
            'evidence' => ['nullable', 'array', 'max:5'],
            'evidence.*' => ['image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
        ]);

        $returns->request(
            $request->user(),
            $order,
            $data['reason'],
            $data['description'] ?? null,
            $request->file('evidence', []) ?? []
        );

        return back()->with('status', 'Return request submitted. The seller will review it.');
    }

    public function storeReview(Request $request, Order $order): RedirectResponse
    {
        abort_unless($order->buyer_id === $request->user()->id, 404);
        abort_unless($order->status === OrderStatus::Completed, 409, 'Rate an order after you confirm it was received.');

        $data = $request->validate([
            'product_id' => ['required', 'integer'],
            'rating' => ['required', 'integer', 'min:1', 'max:5'],
            'comment' => ['nullable', 'string', 'max:1000'],
        ]);

        $item = $order->items()->where('product_id', $data['product_id'])->firstOrFail();

        Review::query()->updateOrCreate(
            [
                'order_id' => $order->id,
                'product_id' => $item->product_id,
                'buyer_id' => $request->user()->id,
            ],
            [
                'seller_id' => $order->seller_id,
                'rating' => $data['rating'],
                'comment' => $data['comment'] ?? null,
            ]
        );

        return back()->with('status', 'Thank you for the rating.');
    }

    public function storeComplaint(Request $request, Order $order): RedirectResponse
    {
        abort_unless($order->buyer_id === $request->user()->id, 404);
        $data = $request->validate([
            'type' => ['required', Rule::in(['order', 'delivery', 'seller', 'other'])],
            'body' => ['required', 'string', 'min:10', 'max:2000'],
        ]);

        Complaint::query()->create([
            'complainant_id' => $request->user()->id,
            'against_user_id' => $order->seller_id,
            'order_id' => $order->id,
            'type' => $data['type'],
            'body' => $data['body'],
            'status' => 'open',
        ]);

        return back()->with('status', 'Your complaint was sent to JEAP support.');
    }
}
