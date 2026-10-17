<?php

namespace App\Enums;

enum KycDocumentType: string
{
    case Id = 'id';
    case BusinessPermit = 'business_permit';
    case OrCr = 'or_cr';
    case DriversLicense = 'drivers_license';
}
