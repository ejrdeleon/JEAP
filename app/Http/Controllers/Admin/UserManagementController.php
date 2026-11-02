<?php

namespace App\Http\Controllers\Admin;

use App\Enums\UserStatus;
use App\Http\Controllers\Controller;
use App\Http\Requests\UpdateAccountAccessRequest;
use App\Models\User;
use Illuminate\Http\RedirectResponse;

class UserManagementController extends Controller
{
    public function updateStatus(UpdateAccountAccessRequest $request, User $user): RedirectResponse
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

        return back()->with('status', 'Account status updated for '.$user->email.'.');
    }
}
