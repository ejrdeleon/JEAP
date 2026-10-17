<?php

namespace App\Http\Controllers\Admin;

use App\Enums\UserStatus;
use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class UserManagementController extends Controller
{
    public function updateStatus(Request $request, User $user): RedirectResponse
    {
        abort_if(
            $user->id === $request->user()->id || $user->hasAnyRole(['admin', 'super-admin']),
            403
        );
        abort_if(
            in_array($user->status, [UserStatus::PendingApproval, UserStatus::Rejected], true),
            403
        );

        $data = $request->validate([
            'status' => ['required', Rule::in([
                UserStatus::Active->value,
                UserStatus::Suspended->value,
                UserStatus::Deactivated->value,
            ])],
        ]);

        $user->forceFill(['status' => $data['status']])->save();

        return back()->with('status', 'Account status updated for '.$user->email.'.');
    }
}
