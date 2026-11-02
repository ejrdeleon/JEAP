<?php

namespace App\Http\Controllers\Seller;

use App\Commerce\ReturnService;
use App\Http\Controllers\Controller;
use App\Models\ReturnRequest;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Illuminate\View\View;

class ReturnController extends Controller
{
    public function index(): View
    {
        return view('seller.returns', [
            'returns' => ReturnRequest::query()
                ->where('seller_id', auth()->id())
                ->with(['order.items', 'buyer'])
                ->latest()
                ->paginate(15),
        ]);
    }

    public function decide(Request $request, ReturnRequest $returnRequest, ReturnService $returns): RedirectResponse
    {
        abort_unless($returnRequest->seller_id === $request->user()->id, 404);
        $data = $request->validate([
            'decision' => ['required', Rule::in(['approved', 'rejected'])],
            'notes' => ['nullable', 'string', 'max:500'],
        ]);
        $returns->decide($returnRequest, $data['decision'], $data['notes'] ?? null);

        return back()->with('status', 'Return request '.$data['decision'].'.');
    }
}
