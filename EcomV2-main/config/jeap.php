<?php

return [
    'commission_rate' => 20.00,
    'commission_recipient' => 'logistics',
    'shipping_fee' => 50.00,
    'min_sellable_stock' => 10,
    'max_qty_per_product' => 10,
    'brand' => 'JEAP',
    'tagline' => 'Shop smart. Delivered easy.',
    'currency' => 'PHP',
    'email_verification_minutes' => (int) env('EMAIL_VERIFICATION_MINUTES', 15),
    'chat_message_max' => 2000,
    'queue' => [
        'driver' => env('QUEUE_CONNECTION', 'database'),
        'redis_available' => (bool) env('REDIS_AVAILABLE', false),
        'note' => 'Redis is preferred for queues. This environment falls back to the database driver when Redis/phpredis is not installed.',
    ],
];
