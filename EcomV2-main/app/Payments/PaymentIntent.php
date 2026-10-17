<?php

namespace App\Payments;

class PaymentIntent
{
    public function __construct(
        public string $status,
        public string $gateway,
        public ?string $reference = null,
        public array $payload = [],
    ) {}
}
