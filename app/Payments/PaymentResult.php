<?php

namespace App\Payments;

class PaymentResult
{
    public function __construct(
        public bool $ok,
        public string $status,
        public ?string $reference = null,
        public array $payload = [],
    ) {}
}
