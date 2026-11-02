<?php

namespace App\Http\Controllers\Api\V1;

use App\Enums\ReviewStatus;
use App\Enums\UserStatus;
use App\Http\Controllers\Controller;
use App\Http\Requests\UpdateAccountAccessRequest;
use App\Models\RegistrationReview;
use App\Models\User;
use App\Notifications\RegistrationDecisionNotification;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Throwable;

class AdminUserController extends Controller
{
    public function updateStatus(UpdateAccountAccessRequest $request, User $user): JsonResponse
    {
        abort_if(
            $user->id === $request->user()->id || $user->hasAnyRole(['admin', 'super-admin']),
            403
        );
        abort_if(
            in_array($user->status, [UserStatus::PendingApproval, UserStatus::Rejected], true),
            403
        );

        $user->applyAccessStatus($request->accessStatus(), $request->accessReason(), $request->user());

        return response()->json([
            'message' => 'Account status updated.',
            'user' => [
                'id' => $user->id,
                'email' => $user->email,
                'status' => $user->status->value,
                'status_reason' => $user->status_reason,
            ],
        ]);
    }

    public function decide(Request $request, User $user): JsonResponse
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
        }

        return response()->json([
            'message' => 'Review saved.',
            'user' => [
                'id' => $user->id,
                'email' => $user->email,
                'status' => $user->status->value,
            ],
            'decision' => $data['decision'],
        ]);
    }
}
