<?php

namespace App\Http\Controllers;

use App\Commerce\ChatService;
use App\Models\Conversation;
use App\Models\Order;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class ChatController extends Controller
{
    public function __construct(private ChatService $chats) {}

    public function index(Request $request): View
    {
        return view('account.chat-index', [
            'conversations' => $this->chats->inbox($request->user()),
        ]);
    }

    public function show(Request $request, Conversation $conversation): View
    {
        abort_unless($conversation->participants()->where('users.id', $request->user()->id)->exists(), 403);
        $this->chats->markRead($conversation, $request->user());
        $conversation->load(['messages.sender', 'participants', 'order.items']);

        return view('account.chat-show', [
            'conversation' => $conversation,
            'conversations' => $this->chats->inbox($request->user()),
        ]);
    }

    public function send(Request $request, Conversation $conversation): RedirectResponse|JsonResponse
    {
        abort_unless($conversation->participants()->where('users.id', $request->user()->id)->exists(), 403);
        $data = $request->validate([
            'message' => ['required', 'string', 'max:'.config('jeap.chat_message_max')],
        ]);
        $message = $this->chats->send($conversation->load('participants'), $request->user(), $data['message']);

        if ($request->expectsJson()) {
            return response()->json([
                'id' => $message->id,
                'body' => $message->body,
                'mine' => true,
                'sender' => $request->user()->name,
                'at' => $message->created_at?->timezone(config('app.timezone'))->format('g:i A'),
            ], 201);
        }

        return back();
    }

    public function messages(Request $request, Conversation $conversation): JsonResponse
    {
        abort_unless($conversation->participants()->where('users.id', $request->user()->id)->exists(), 403);
        $this->chats->markRead($conversation, $request->user());
        $afterId = (int) $request->query('after', 0);
        $messages = $conversation->messages()
            ->with('sender')
            ->when($afterId > 0, fn ($query) => $query->where('id', '>', $afterId))
            ->orderBy('id')
            ->get()
            ->map(fn ($message) => [
                'id' => $message->id,
                'body' => $message->body,
                'mine' => $message->user_id === $request->user()->id,
                'sender' => $message->sender?->name,
                'at' => $message->created_at?->timezone(config('app.timezone'))->format('g:i A'),
            ]);

        return response()->json(['messages' => $messages]);
    }

    public function start(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'order_id' => ['nullable', 'integer', 'exists:orders,id'],
            'seller_id' => ['nullable', 'integer', 'exists:users,id'],
            'message' => ['nullable', 'string', 'max:'.config('jeap.chat_message_max')],
        ]);

        if (! empty($data['order_id'])) {
            $order = Order::query()->with(['buyer', 'seller', 'parcel.deliveryAssignment.courier', 'parcel.pickupAssignment.courier'])->findOrFail($data['order_id']);
            $conversation = $this->chats->forOrder($order, $request->user());
        } elseif (! empty($data['seller_id'])) {
            $seller = User::query()->findOrFail($data['seller_id']);
            $conversation = $this->chats->withSeller($request->user(), $seller);
        } else {
            return back()->withErrors(['message' => 'Choose an order or a shop to start a chat.']);
        }

        if (! empty($data['message'])) {
            $this->chats->send($conversation->load('participants'), $request->user(), $data['message']);
        }

        return redirect()->route('chat.show', $conversation);
    }
}
