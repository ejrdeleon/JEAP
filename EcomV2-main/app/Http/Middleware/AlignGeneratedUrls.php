<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\URL;
use Symfony\Component\HttpFoundation\Response;

class AlignGeneratedUrls
{
    public function handle(Request $request, Closure $next): Response
    {
        $root = $request->root();
        $https = $request->secure()
            || strtolower((string) $request->headers->get('X-Forwarded-Proto')) === 'https';

        if ($https) {
            $root = preg_replace('#^http://#i', 'https://', $root) ?: $root;
            URL::forceScheme('https');
        }

        URL::forceRootUrl(rtrim($root, '/'));

        return $next($request);
    }
}
