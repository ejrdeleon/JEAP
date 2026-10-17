<?php

namespace App\Http\Controllers\Logistics;

use App\Enums\ReviewStatus;
use App\Enums\UserStatus;
use App\Http\Controllers\Controller;
use App\Models\RegistrationReview;
use App\Models\User;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class CourierReviewController extends Controller
{
    public function index(): View
    {
        $users = User::query()
            ->role('courier')
            ->where('status', UserStatus::PendingApproval)
            ->with('courierProfile', 'kycDocuments')
            ->latest()
            ->get();

        return view('logistics.courier-reviews', compact('users'));
    }

    public function decide(Request $request, User $user): RedirectResponse
    {
        abort_unless($user->hasRole('courier'), 403);
        abort_if($user->hasRole('admin') || $user->id === $request->user()->id, 403);
        abort_unless($user->status === UserStatus::PendingApproval, 403);

        $data = $request->validate([
            'decision' => ['required', 'in:approved,rejected'],
            'notes' => ['nullable', 'string', 'max:2000'],
        ]);

        $user->forceFill([
            'status' => $data['decision'] === 'approved' ? UserStatus::Active : UserStatus::Rejected,
        ])->save();

        if ($data['decision'] === 'approved' && $user->courierProfile) {
            $user->courierProfile->update(['approved_by' => $request->user()->id]);
        }

        RegistrationReview::create([
            'user_id' => $user->id,
            'reviewer_id' => $request->user()->id,
            'decision' => $data['decision'] === 'approved' ? ReviewStatus::Approved : ReviewStatus::Rejected,
            'notes' => $data['notes'] ?? null,
            'notified_at' => now(),
        ]);

        return back()->with('status', 'Courier review saved for '.$user->email);
    }
}
