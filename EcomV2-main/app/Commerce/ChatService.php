<?php

namespace App\Commerce;

use App\Models\Conversation;
use App\Models\Message;
use App\Models\Order;
use App\Models\User;
use App\Notifications\ChatMessageNotification;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class ChatService
{
    public function inbox(User $user): Collection
    {
        return Conversation::query()
            ->whereHas('participants', fn ($query) => $query->where('users.id', $user->id))
            ->with(['latestMessage.sender', 'participants', 'order'])
            ->latest('updated_at')
            ->get()
            ->map(function (Conversation $conversation) use ($user) {
                $conversation->unread_count = $conversation->messages()
                    ->where('user_id', '!=', $user->id)
                    ->whereNull('read_at')
                    ->count();
                $conversation->counterpart = $conversation->otherParticipant($user);

                return $conversation;
            });
    }

    public function unreadCount(User $user): int
    {
        return Message::query()
            ->whereNull('read_at')
            ->where('user_id', '!=', $user->id)
            ->whereHas('conversation.participants', fn ($query) => $query->where('users.id', $user->id))
            ->count();
    }

    public function forOrder(Order $order, User $actor): Conversation
    {
        $order->loadMissing(['buyer', 'seller', 'parcel.deliveryAssignment', 'parcel.pickupAssignment']);
        $allowed = array_filter([
            $order->buyer_id,
            $order->seller_id,
            $order->parcel?->deliveryAssignment?->courier_id,
            $order->parcel?->pickupAssignment?->courier_id,
        ]);
        abort_unless(in_array($actor->id, $allowed, true) || $actor->hasRole('super-admin'), 403);

        return DB::transaction(function () use ($order, $actor): Conversation {
            $conversation = Conversation::query()->where('order_id', $order->id)->lockForUpdate()->first();
            if (! $conversation) {
                $conversation = Conversation::query()->create([
                    'order_id' => $order->id,
                    'subject' => 'Order '.$order->order_number,
                ]);
            }

            $this->ensureParticipant($conversation, $order->buyer);
            $this->ensureParticipant($conversation, $order->seller);
            $this->ensureParticipant($conversation, $actor);

            $courier = $order->parcel?->deliveryAssignment?->courier
                ?? $order->parcel?->pickupAssignment?->courier;
            if ($courier) {
                $this->ensureParticipant($conversation, $courier);
            }

            return $conversation->load(['participants', 'order']);
        });
    }

    public function withSeller(User $buyer, User $seller): Conversation
    {
        abort_unless($buyer->hasRole('buyer') || $buyer->hasRole('super-admin'), 403);
        abort_unless($seller->hasRole('seller') || $seller->hasRole('super-admin'), 403);

        return DB::transaction(function () use ($buyer, $seller): Conversation {
            $conversation = Conversation::query()
                ->whereNull('order_id')
                ->whereHas('participants', fn ($query) => $query->where('users.id', $buyer->id))
                ->whereHas('participants', fn ($query) => $query->where('users.id', $seller->id))
                ->lockForUpdate()
                ->first();

            if (! $conversation) {
                $conversation = Conversation::query()->create([
                    'subject' => 'Chat with '.($seller->sellerProfile?->business_name ?: $seller->name),
                ]);
            }

            $this->ensureParticipant($conversation, $buyer);
            $this->ensureParticipant($conversation, $seller);

            return $conversation->load('participants');
        });
    }

    public function addParticipant(Conversation $conversation, User $user): void
    {
        $this->ensureParticipant($conversation, $user);
    }

    public function send(Conversation $conversation, User $sender, string $body): Message
    {
        abort_unless($conversation->participants()->where('users.id', $sender->id)->exists(), 403);

        $conversation->loadMissing('participants');
        $message = $conversation->messages()->create([
            'user_id' => $sender->id,
            'body' => $body,
        ]);
        $conversation->touch();

        $preview = Str::limit($body, 80);
        $conversation->participants
            ->where('id', '!=', $sender->id)
            ->each(function (User $participant) use ($sender, $conversation, $preview): void {
                if ($participant->wantsNotification('chat')) {
                    $participant->notify(new ChatMessageNotification($conversation, $sender, $preview));
                }
            });

        return $message;
    }

    public function markRead(Conversation $conversation, User $reader): void
    {
        $conversation->messages()
            ->where('user_id', '!=', $reader->id)
            ->whereNull('read_at')
            ->update(['read_at' => now()]);
    }

    private function ensureParticipant(Conversation $conversation, ?User $user): void
    {
        if (! $user) {
            return;
        }

        $conversation->participants()->syncWithoutDetaching([$user->id]);
    }
}
