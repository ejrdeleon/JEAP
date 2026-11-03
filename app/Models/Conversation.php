<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Conversation extends Model
{
    protected $fillable = [
        'order_id',
        'subject',
    ];

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    public function participants(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'conversation_participants')->withTimestamps();
    }

    public function messages(): HasMany
    {
        return $this->hasMany(Message::class);
    }

    public function latestMessage(): HasOne
    {
        return $this->hasOne(Message::class)->latestOfMany();
    }

    public function otherParticipant(User $user): ?User
    {
        return $this->counterpartFor($user);
    }

    public function counterpartFor(User $user): ?User
    {
        $this->loadMissing(['participants.roles', 'participants.sellerProfile']);
        $others = $this->participants->where('id', '!=', $user->id);

        if ($user->hasRole('buyer')) {
            return $others->first(fn (User $participant) => $participant->hasRole('seller'))
                ?? $others->first();
        }

        if ($user->hasRole('seller')) {
            return $others->first(fn (User $participant) => $participant->hasRole('buyer'))
                ?? $others->first();
        }

        return $others->first();
    }

    public function counterpartLabel(User $user): string
    {
        $counterpart = $this->counterpartFor($user);
        if (! $counterpart) {
            return $this->subject ?: 'JEAP chat';
        }

        if ($counterpart->hasRole('seller')) {
            return $counterpart->sellerProfile?->business_name ?: $counterpart->name;
        }

        return $counterpart->name;
    }

    public function counterpartRole(User $user): string
    {
        $counterpart = $this->counterpartFor($user);
        if (! $counterpart) {
            return 'Chat';
        }
        if ($counterpart->hasRole('seller')) {
            return 'Seller';
        }
        if ($counterpart->hasRole('courier')) {
            return 'Rider';
        }
        if ($counterpart->hasRole('logistics')) {
            return 'JEAP Dash';
        }
        if ($counterpart->hasAnyRole(['admin', 'super-admin'])) {
            return 'JEAP';
        }

        return 'Buyer';
    }

    public function orderUrlFor(User $user): ?string
    {
        if (! $this->order) {
            return null;
        }
        if ($this->order->buyer_id === $user->id) {
            return route('buyer.orders.track', $this->order);
        }
        if ($this->order->seller_id === $user->id) {
            return route('seller.orders');
        }
        if ($user->hasRole('courier')) {
            return route('courier.dashboard');
        }

        return null;
    }

    public static function stamp(?\Carbon\CarbonInterface $at): string
    {
        if (! $at) {
            return '';
        }

        $at = $at->timezone(config('app.timezone'));
        if ($at->isToday()) {
            return $at->format('g:i A');
        }
        if ($at->isYesterday()) {
            return 'Yesterday';
        }
        if ($at->isCurrentYear()) {
            return $at->format('M j');
        }

        return $at->format('M j, Y');
    }
}
