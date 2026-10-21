<?php

return [
    'commission_rate' => 20.00,
    'commission_recipient' => 'logistics',
    'shipping_fee' => 50.00,
    'min_sellable_stock' => 10,
    'max_qty_per_product' => 10,
    'brand' => 'JEAP',
    'tagline' => 'Shop smart. Delivered easy.',
    'hotline' => '(025) 3686 25 16',
    'currency' => 'PHP',
    'queue' => [
        'driver' => env('QUEUE_CONNECTION', 'database'),
        'redis_available' => (bool) env('REDIS_AVAILABLE', false),
        'note' => 'Redis is preferred for queues. This environment falls back to the database driver when Redis/phpredis is not installed.',
    ],
];
