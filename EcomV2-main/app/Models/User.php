<?php

namespace App\Models;

use App\Enums\UserStatus;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Casts\Attribute;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\Relations\MorphMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Spatie\Permission\Traits\HasRoles;

class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, HasRoles, Notifiable;

    protected $fillable = [
        'first_name',
        'middle_name',
        'last_name',
        'sex',
        'email',
        'phone',
        'birthday',
        'terms_accepted_at',
        'password',
        'avatar_path',
        'notification_preferences',
        'google_id',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'birthday' => 'date',
            'terms_accepted_at' => 'datetime',
            'password' => 'hashed',
            'status' => UserStatus::class,
            'status_changed_at' => 'datetime',
            'notification_preferences' => 'array',
        ];
    }

    protected function name(): Attribute
    {
        return Attribute::get(function (): string {
            return trim(implode(' ', array_filter([
                $this->first_name,
                $this->middle_name,
                $this->last_name,
            ])));
        });
    }

    protected function age(): Attribute
    {
        return Attribute::get(fn (): ?int => $this->birthday?->age);
    }

    public function isApproved(): bool
    {
        return $this->status === UserStatus::Active;
    }

    public function initials(): string
    {
        $first = mb_substr(trim((string) $this->first_name), 0, 1);
        $last = mb_substr(trim((string) $this->last_name), 0, 1);

        return mb_strtoupper($first.$last) ?: '?';
    }

    public function applyAccessStatus(UserStatus $status, ?string $reason, self $actor): void
    {
        $restricted = in_array($status, [UserStatus::Suspended, UserStatus::Deactivated], true);

        $this->forceFill([
            'status' => $status,
            'status_reason' => $restricted ? trim((string) $reason) : null,
            'status_changed_by' => $actor->id,
            'status_changed_at' => now(),
        ])->save();
    }

    public function signInBlockMessage(): string
    {
        $reason = trim((string) $this->status_reason);

        return match ($this->status) {
            UserStatus::Unverified => 'Verify your email before signing in.',
            UserStatus::PendingApproval => 'Your account is pending approval. You cannot sign in yet.',
            UserStatus::PendingActivation => 'Activate your rider account using the link sent to your email before signing in.',
            UserStatus::Suspended => $reason !== ''
                ? 'Your account is suspended. '.$reason
                : 'Your account is suspended.',
            UserStatus::Deactivated => $reason !== ''
                ? 'Your account is deactivated. '.$reason
                : 'Your account is deactivated.',
            default => 'Your account is not active.',
        };
    }

    public function statusChangedBy(): BelongsTo
    {
        return $this->belongsTo(self::class, 'status_changed_by');
    }

    public function avatarUrl(): ?string
    {
        if (! $this->avatar_path) {
            return null;
        }

        if (str_starts_with($this->avatar_path, 'http://') || str_starts_with($this->avatar_path, 'https://')) {
            return $this->avatar_path;
        }

        return route('media.avatar', $this).'?v='.($this->updated_at?->timestamp ?? time());
    }

    public function notificationPreferenceMap(): array
    {
        return array_merge([
            'order_updates' => true,
            'chat' => true,
            'promos' => true,
        ], $this->notification_preferences ?? []);
    }

    public function wantsNotification(string $channel): bool
    {
        return (bool) ($this->notificationPreferenceMap()[$channel] ?? true);
    }

    public function conversations(): BelongsToMany
    {
        return $this->belongsToMany(Conversation::class, 'conversation_participants')->withTimestamps();
    }

    public function sellerProfile(): HasOne
    {
        return $this->hasOne(SellerProfile::class);
    }

    public function courierProfile(): HasOne
    {
        return $this->hasOne(CourierProfile::class);
    }

    public function logisticsProfile(): HasOne
    {
        return $this->hasOne(LogisticsProfile::class);
    }

    public function kycDocuments(): HasMany
    {
        return $this->hasMany(KycDocument::class);
    }

    public function addresses(): MorphMany
    {
        return $this->morphMany(Address::class, 'addressable');
    }

    public function products(): HasMany
    {
        return $this->hasMany(Product::class, 'seller_id');
    }

    public function wishlistProducts(): BelongsToMany
    {
        return $this->belongsToMany(Product::class, 'buyer_wishlists', 'buyer_id', 'product_id')->withTimestamps();
    }

    public function followedSellers(): BelongsToMany
    {
        return $this->belongsToMany(self::class, 'buyer_followed_sellers', 'buyer_id', 'seller_id')->withTimestamps();
    }
}
