<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class ForwardXsrfCookie
{
    public function handle(Request $request, Closure $next): Response
    {
        if ($request->isMethodSafe() || $request->headers->has('X-XSRF-TOKEN') || $request->headers->has('X-CSRF-TOKEN')) {
            return $next($request);
        }

        $cookie = $request->cookies->get('XSRF-TOKEN');
        if (is_string($cookie) && $cookie !== '') {
            $request->headers->set('X-XSRF-TOKEN', $cookie);
        }

        return $next($request);
    }
}
