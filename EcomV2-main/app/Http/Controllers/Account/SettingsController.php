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
        return view('account.password', ['user' => auth()->user()]);
    }

    public function updatePassword(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'current_password' => ['required', 'current_password'],
            'password' => ['required', 'confirmed', Password::defaults()],
        ]);

        $request->user()->update([
            'password' => $data['password'],
        ]);

        return back()->with('toast', 'Password updated.');
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
