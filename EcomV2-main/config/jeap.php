<?php

return [
    'commission_rate' => 10.00,
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
