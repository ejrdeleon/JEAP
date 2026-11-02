<?php

namespace App\Http\Controllers\Logistics;

use App\Commerce\RemittanceService;
use App\Http\Controllers\Controller;
use App\Models\CodRemittance;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class RemittanceController extends Controller
{
    public function index(): View
    {
        $user = auth()->user();

        return view('logistics.remittances', [
            'remittances' => CodRemittance::query()
                ->with(['courier', 'orders'])
                ->when(! $user->hasAnyRole(['admin', 'super-admin']), fn ($query) => $query->where('logistics_id', $user->id))
                ->latest()
                ->paginate(15),
        ]);
    }

    public function confirm(Request $request, CodRemittance $remittance, RemittanceService $remittances): RedirectResponse
    {
        $user = $request->user();
        abort_unless(
            $user->hasAnyRole(['admin', 'super-admin']) || $remittance->logistics_id === $user->id,
            403
        );
        $remittances->confirm($user, $remittance);

        return back()->with('status', 'Cash received. Seller commission for these orders is marked paid.');
    }
}
