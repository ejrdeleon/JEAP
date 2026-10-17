<?php

namespace App\Enums;

enum UserStatus: string
{
    case PendingApproval = 'pending_approval';
    case Active = 'active';
    case Suspended = 'suspended';
    case Rejected = 'rejected';
    case Deactivated = 'deactivated';

    public function label(): string
    {
        return match ($this) {
            self::PendingApproval => 'Pending approval',
            self::Active => 'Active',
            self::Suspended => 'Suspended',
            self::Rejected => 'Rejected',
            self::Deactivated => 'Deactivated',
        };
    }
}
