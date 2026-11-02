<?php

namespace App\Payments;

use App\Enums\PaymentStatus;
use App\Models\Order;
use Illuminate\Http\Request;

class CodGateway implements PaymentGateway
{
    public function initiate(Order $order): PaymentIntent
    {
        return new PaymentIntent(
            status: PaymentStatus::Pending->value,
            gateway: 'cod',
            reference: 'COD-'.$order->order_number,
            payload: [
                'message' => 'Cash on delivery. No online capture.',
            ],
        );
    }

    public function handleWebhook(Request $request): PaymentResult
    {
        return new PaymentResult(
            ok: false,
            status: PaymentStatus::Pending->value,
            payload: ['message' => 'COD has no webhook.'],
        );
    }
}
