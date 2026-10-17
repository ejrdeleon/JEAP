<?php

require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Http\Kernel::class);

$request = Illuminate\Http\Request::create('/login', 'POST', [
    '_token' => 'invalid',
    'email' => 'seller@jeap.test',
    'password' => 'password',
]);

$response = $kernel->handle($request);
echo "Status: " . $response->getStatusCode() . PHP_EOL;
if ($response->isRedirection()) {
    echo "Redirect to: " . $response->headers->get('Location') . PHP_EOL;
} else {
    echo "Content: " . substr($response->getContent(), 0, 200) . PHP_EOL;
}

