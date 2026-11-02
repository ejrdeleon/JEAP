<?php

namespace App\Events;

use App\Models\Shipment;
use App\Models\ShipmentCheckpoint;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class ShipmentMilestoneUpdated
{
    use Dispatchable, SerializesModels;

    public function __construct(
        public Shipment $shipment,
        public ShipmentCheckpoint $checkpoint,
    ) {}
}
