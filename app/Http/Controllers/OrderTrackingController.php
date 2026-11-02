<?php

namespace App\Http\Controllers;

use App\Models\Order;
use App\Services\ShipmentService;
use Illuminate\Http\Request;
use Illuminate\View\View;

class OrderTrackingController extends Controller
{
    public function show(Request $request, Order $order, ShipmentService $shipments): View
    {
        $user = $request->user();
        abort_unless(
            $user && ($order->buyer_id === $user->id || $user->hasAnyRole(['admin', 'super-admin'])),
            403
        );

        $shipment = $shipments->initializeShipment($order);
        $shipment->load(['order.items', 'courier', 'checkpoints.loggedBy']);

        return view('orders.tracking', [
            'order' => $order->load(['seller.sellerProfile', 'items']),
            'shipment' => $shipment,
            'checkpoints' => $shipment->checkpoints,
            'progressStep' => $shipment->progress_bar_step,
        ]);
    }
}
