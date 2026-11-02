<?php

namespace App\Enums;

enum KycDocumentType: string
{
    case Id = 'id';
    case BusinessPermit = 'business_permit';
    case OrCr = 'or_cr';
    case DriversLicense = 'drivers_license';
    case DtiCertificate = 'dti_certificate';
    case SecCertificate = 'sec_certificate';
    case Bir2303 = 'bir_2303';
    case RepresentativeId = 'representative_id';
    case MayorsPermit = 'mayors_permit';
    case VehicleRegistration = 'vehicle_registration';
}
