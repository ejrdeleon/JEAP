<?php

namespace App\Http\Controllers\Courier;

use App\Commerce\RemittanceService;
use App\Http\Controllers\Controller;
use App\Models\CodRemittance;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class RemittanceController extends Controller
{
    public function index(RemittanceService $remittances): View
    {
        $user = auth()->user();

        return view('courier.remittances', [
            'pendingOrders' => $remittances->pendingOrders($user),
            'history' => CodRemittance::query()
                ->where('courier_id', $user->id)
                ->with('orders')
                ->latest()
                ->paginate(10),
        ]);
    }

    public function store(Request $request, RemittanceService $remittances): RedirectResponse
    {
        $data = $request->validate([
            'order_ids' => ['required', 'array', 'min:1'],
            'order_ids.*' => ['integer'],
            'notes' => ['nullable', 'string', 'max:500'],
        ]);
        $remittances->submit($request->user(), $data['order_ids'], $data['notes'] ?? null);

        return back()->with('status', 'COD remittance submitted to your sorting center.');
    }
}
