<?php

namespace App\Http\Controllers\Account;

use App\Http\Controllers\Controller;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rules\Password;
use Illuminate\View\View;

class SettingsController extends Controller
{
    public function password(): View
    {
        $user = auth()->user();

        return view('account.password', [
            'user' => $user,
            'needsCurrentPassword' => $user->hasLocalPassword(),
        ]);
    }

    public function updatePassword(Request $request): RedirectResponse
    {
        $needsCurrent = $request->user()->hasLocalPassword();
        $rules = [
            'password' => ['required', 'confirmed', Password::defaults()],
        ];
        if ($needsCurrent) {
            $rules['current_password'] = ['required', 'current_password'];
        }

        $data = $request->validate($rules);

        $request->user()->forceFill([
            'password' => $data['password'],
            'password_set_at' => now(),
        ])->save();

        return back()->with('toast', $needsCurrent ? 'Password updated.' : 'Password saved. You can now log in with email as well as Google.');
    }

    public function notifications(): View
    {
        return view('account.notification-settings', [
            'user' => auth()->user(),
            'preferences' => auth()->user()->notificationPreferenceMap(),
        ]);
    }

    public function updateNotifications(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'order_updates' => ['nullable', 'boolean'],
            'chat' => ['nullable', 'boolean'],
            'promos' => ['nullable', 'boolean'],
        ]);

        $request->user()->forceFill([
            'notification_preferences' => [
                'order_updates' => $request->boolean('order_updates'),
                'chat' => $request->boolean('chat'),
                'promos' => $request->boolean('promos'),
            ],
        ])->save();

        return back()->with('toast', 'Notification preferences saved.');
    }
}
