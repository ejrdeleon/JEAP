<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class SanitizeInput
{
    /** @var list<string> */
    private const SKIP = [
        'password',
        'password_confirmation',
        'current_password',
        '_token',
        '_method',
    ];

    public function handle(Request $request, Closure $next): Response
    {
        $cleaned = $this->clean($request->except(self::SKIP));
        if (is_array($cleaned)) {
            $request->merge($cleaned);
        }

        return $next($request);
    }

    private function clean(mixed $value, string|int|null $key = null): mixed
    {
        if (is_string($key) && in_array($key, self::SKIP, true)) {
            return $value;
        }

        if (is_array($value)) {
            $out = [];
            foreach ($value as $childKey => $child) {
                $out[$childKey] = $this->clean($child, $childKey);
            }

            return $out;
        }

        if (! is_string($value)) {
            return $value;
        }

        return trim(strip_tags($value));
    }
}
