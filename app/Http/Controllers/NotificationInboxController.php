<?php

namespace App\Http\Controllers;

use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class NotificationInboxController extends Controller
{
    public function index(Request $request): View
    {
        return view('account.notifications', [
            'notifications' => $request->user()->notifications()->latest()->paginate(20),
        ]);
    }

    public function read(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'id' => ['nullable', 'uuid'],
        ]);

        if (! empty($data['id'])) {
            $request->user()->notifications()->whereKey($data['id'])->update(['read_at' => now()]);
        } else {
            $request->user()->unreadNotifications->markAsRead();
        }

        return back();
    }
}
