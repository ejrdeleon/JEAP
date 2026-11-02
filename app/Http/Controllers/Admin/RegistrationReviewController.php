<?php

namespace App\Http\Controllers\Admin;

use App\Enums\ReviewStatus;
use App\Enums\UserStatus;
use App\Http\Controllers\Controller;
use App\Models\RegistrationReview;
use App\Models\User;
use App\Notifications\RegistrationDecisionNotification;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;
use Throwable;

class RegistrationReviewController extends Controller
{
    public function index(): View
    {
        $users = User::query()
            ->where('status', UserStatus::PendingApproval)
            ->whereDoesntHave('roles', fn ($q) => $q->where('name', 'courier'))
            ->with('roles', 'kycDocuments', 'sellerProfile', 'logisticsProfile')
            ->latest()
            ->get();

        return view('admin.verifications', compact('users'));
    }

    public function decide(Request $request, User $user): RedirectResponse
    {
        abort_if($user->hasAnyRole(['admin', 'super-admin']) || $user->id === $request->user()->id, 403);
        abort_unless($user->status === UserStatus::PendingApproval, 403);
        abort_unless($user->hasAnyRole(['seller', 'logistics']), 403);

        $data = $request->validate([
            'decision' => ['required', 'in:approved,rejected'],
            'notes' => ['required_if:decision,rejected', 'nullable', 'string', 'max:2000'],
        ]);

        $user->forceFill([
            'status' => $data['decision'] === 'approved' ? UserStatus::Active : UserStatus::Rejected,
        ])->save();
        $review = RegistrationReview::create([
            'user_id' => $user->id,
            'reviewer_id' => $request->user()->id,
            'decision' => $data['decision'] === 'approved' ? ReviewStatus::Approved : ReviewStatus::Rejected,
            'notes' => $data['notes'] ?? null,
        ]);

        try {
            $user->notify(new RegistrationDecisionNotification($data['decision'], $data['notes'] ?? null));
            $review->forceFill(['notified_at' => now()])->save();
        } catch (Throwable $exception) {
            report($exception);

            return back()->with('status', 'Review saved. Email notification could not be sent; contact the applicant directly.');
        }

        return back()->with('status', 'Review saved and the applicant was emailed.');
    }
}
