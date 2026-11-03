<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Notifications\ChatMessageNotification;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Notifications\DatabaseNotification;

class NotificationController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $notifications = $request->user()->activityNotifications()->latest()->limit(50)->get();

        return response()->json([
            'unread_count' => $request->user()->unreadActivityNotificationCount(),
            'notifications' => $notifications->map(fn (DatabaseNotification $notification) => $this->payload($notification))->values(),
        ]);
    }

    public function markAsRead(Request $request, string $id): JsonResponse
    {
        $notification = $request->user()->notifications()->whereKey($id)->firstOrFail();
        $notification->markAsRead();

        return response()->json(['message' => 'Notification marked as read.']);
    }

    public function markAllAsRead(Request $request): JsonResponse
    {
        $request->user()->unreadNotifications()
            ->where('type', '!=', ChatMessageNotification::class)
            ->update(['read_at' => now()]);

        return response()->json(['message' => 'All notifications marked as read.']);
    }

    public function preferences(Request $request): JsonResponse
    {
        return response()->json([
            'preferences' => $request->user()->notificationPreferenceMap(),
        ]);
    }

    public function updatePreferences(Request $request): JsonResponse
    {
        $request->validate([
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

        return response()->json([
            'message' => 'Notification preferences saved.',
            'preferences' => $request->user()->notificationPreferenceMap(),
        ]);
    }

    private function payload(DatabaseNotification $notification): array
    {
        $data = is_array($notification->data) ? $notification->data : [];

        return [
            'id' => $notification->id,
            'type' => class_basename($notification->type),
            'title' => $data['title'] ?? $data['subject'] ?? class_basename($notification->type),
            'message' => $data['message'] ?? $data['body'] ?? $data['line'] ?? '',
            'read' => $notification->read_at !== null,
            'created_at' => $notification->created_at?->toIso8601String(),
            'data' => $data,
        ];
    }
}
