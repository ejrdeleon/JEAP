<?php

namespace App\Enums;

enum UserStatus: string
{
    case Unverified = 'unverified';
    case PendingApproval = 'pending_approval';
    case PendingActivation = 'pending_activation';
    case Active = 'active';
    case Suspended = 'suspended';
    case Rejected = 'rejected';
    case Deactivated = 'deactivated';

    public function label(): string
    {
        return match ($this) {
            self::Unverified => 'Unverified',
            self::PendingApproval => 'Pending approval',
            self::PendingActivation => 'Pending activation',
            self::Active => 'Active',
            self::Suspended => 'Suspended',
            self::Rejected => 'Rejected',
            self::Deactivated => 'Deactivated',
        };
    }
}
