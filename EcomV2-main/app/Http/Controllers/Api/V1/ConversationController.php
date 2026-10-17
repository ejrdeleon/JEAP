<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Order;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ConversationController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $userId = $request->user()->id;

        $conversations = DB::table('conversations')
            ->join('conversation_participants', 'conversations.id', '=', 'conversation_participants.conversation_id')
            ->where('conversation_participants.user_id', $userId)
            ->select('conversations.*')
            ->latest('conversations.updated_at')
            ->get()
            ->map(function ($conv) use ($userId) {
                $participants = DB::table('conversation_participants')
                    ->join('users', 'users.id', '=', 'conversation_participants.user_id')
                    ->where('conversation_participants.conversation_id', $conv->id)
                    ->where('conversation_participants.user_id', '!=', $userId)
                    ->select('users.id', DB::raw("CONCAT(users.first_name, ' ', users.last_name) as name"))
                    ->get();

                $lastMessage = DB::table('messages')
                    ->where('conversation_id', $conv->id)
                    ->latest()
                    ->first();

                return [
                    'id' => $conv->id,
                    'subject' => $conv->subject,
                    'order_id' => $conv->order_id,
                    'participants' => $participants,
                    'last_message' => $lastMessage ? [
                        'body' => $lastMessage->body,
                        'sent_at' => $lastMessage->created_at,
                    ] : null,
                ];
            });

        return response()->json($conversations);
    }

    public function messages(Request $request, int $conversationId): JsonResponse
    {
        $userId = $request->user()->id;

        $isMember = DB::table('conversation_participants')
            ->where('conversation_id', $conversationId)
            ->where('user_id', $userId)
            ->exists();

        abort_unless($isMember, 403);

        $messages = DB::table('messages')
            ->join('users', 'users.id', '=', 'messages.user_id')
            ->where('messages.conversation_id', $conversationId)
            ->select(
                'messages.id',
                'messages.body',
                'messages.user_id',
                DB::raw("CONCAT(users.first_name, ' ', users.last_name) as sender_name"),
                'messages.created_at',
                DB::raw("messages.user_id = {$userId} as is_mine")
            )
            ->orderBy('messages.created_at')
            ->get();

        // Mark as read
        DB::table('messages')
            ->where('conversation_id', $conversationId)
            ->where('user_id', '!=', $userId)
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        return response()->json($messages);
    }

    public function send(Request $request, int $conversationId): JsonResponse
    {
        $userId = $request->user()->id;

        $isMember = DB::table('conversation_participants')
            ->where('conversation_id', $conversationId)
            ->where('user_id', $userId)
            ->exists();

        abort_unless($isMember, 403);

        $data = $request->validate(['message' => ['required', 'string', 'max:2000']]);

        $messageId = DB::table('messages')->insertGetId([
            'conversation_id' => $conversationId,
            'user_id' => $userId,
            'body' => $data['message'],
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        DB::table('conversations')->where('id', $conversationId)->update(['updated_at' => now()]);

        return response()->json(['message' => 'Sent.', 'id' => $messageId], 201);
    }

    public function start(Request $request): JsonResponse
    {
        $data = $request->validate([
            'order_number' => ['required', 'string'],
            'message' => ['required', 'string', 'max:2000'],
        ]);

        $order = Order::query()->where('order_number', $data['order_number'])
            ->where(fn (Builder $q) => $q->where('buyer_id', $request->user()->id)->orWhere('seller_id', $request->user()->id))
            ->firstOrFail();

        $otherUserId = $order->buyer_id === $request->user()->id ? $order->seller_id : $order->buyer_id;

        $conversationId = DB::transaction(function () use ($request, $order, $otherUserId, $data): int {
            // Reuse existing conversation for this order if any
            $existing = DB::table('conversations')->where('order_id', $order->id)->value('id');

            if (! $existing) {
                $existing = DB::table('conversations')->insertGetId([
                    'order_id' => $order->id,
                    'subject' => 'Order '.$order->order_number,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
                DB::table('conversation_participants')->insert([
                    ['conversation_id' => $existing, 'user_id' => $request->user()->id, 'created_at' => now(), 'updated_at' => now()],
                    ['conversation_id' => $existing, 'user_id' => $otherUserId, 'created_at' => now(), 'updated_at' => now()],
                ]);
            }

            DB::table('messages')->insert([
                'conversation_id' => $existing,
                'user_id' => $request->user()->id,
                'body' => $data['message'],
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            DB::table('conversations')->where('id', $existing)->update(['updated_at' => now()]);

            return $existing;
        });

        return response()->json(['message' => 'Conversation started.', 'conversation_id' => $conversationId], 201);
    }
}
