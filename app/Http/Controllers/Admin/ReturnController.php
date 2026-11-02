<?php

namespace App\Http\Controllers\Admin;

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
        return view('admin.returns', [
            'returns' => ReturnRequest::query()->with(['order', 'buyer', 'seller'])->latest()->paginate(20),
        ]);
    }

    public function decide(Request $request, ReturnRequest $returnRequest, ReturnService $returns): RedirectResponse
    {
        $data = $request->validate([
            'decision' => ['required', Rule::in(['approved', 'rejected'])],
            'notes' => ['nullable', 'string', 'max:500'],
        ]);
        $returns->decide($returnRequest, $data['decision'], $data['notes'] ?? null);

        return back()->with('status', 'Return request '.$data['decision'].'.');
    }
}
