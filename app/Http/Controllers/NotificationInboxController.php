<?php

namespace App\Http\Controllers;

use App\Notifications\ChatMessageNotification;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class NotificationInboxController extends Controller
{
    public function index(Request $request): View
    {
        return view('account.notifications', [
            'notifications' => $request->user()->activityNotifications()->latest()->paginate(20),
        ]);
    }

    public function open(Request $request, string $notification): RedirectResponse
    {
        $record = $request->user()->notifications()->whereKey($notification)->firstOrFail();
        $record->markAsRead();
        $url = is_array($record->data) ? ($record->data['url'] ?? null) : null;

        return $url ? redirect()->to($url) : redirect()->route('notifications.index');
    }

    public function read(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'id' => ['nullable', 'uuid'],
        ]);

        if (! empty($data['id'])) {
            $request->user()->notifications()->whereKey($data['id'])->update(['read_at' => now()]);
        } else {
            $request->user()->unreadNotifications()
                ->where('type', '!=', ChatMessageNotification::class)
                ->update(['read_at' => now()]);
        }

        return back();
    }
}
