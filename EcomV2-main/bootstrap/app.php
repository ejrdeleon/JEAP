<?php

use App\Http\Middleware\AlignGeneratedUrls;
use App\Http\Middleware\EnsureUserIsApproved;
use App\Http\Middleware\ForceJsonResponse;
use App\Http\Middleware\ForwardXsrfCookie;
use App\Http\Middleware\SanitizeInput;
use App\Http\Middleware\SecurityHeaders;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Spatie\Permission\Middleware\PermissionMiddleware;
use Spatie\Permission\Middleware\RoleMiddleware;
use Spatie\Permission\Middleware\RoleOrPermissionMiddleware;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->trustProxies(at: '*');
        $middleware->trustHosts(at: ['jeap.store', 'www.jeap.store', '127.0.0.1', 'localhost']);
        $middleware->prepend(SanitizeInput::class);
        $middleware->web(prepend: [
            AlignGeneratedUrls::class,
            ForwardXsrfCookie::class,
        ]);
        $middleware->append(SecurityHeaders::class);
        $middleware->api(prepend: [
            ForceJsonResponse::class,
        ]);
        $middleware->alias([
            'role' => RoleMiddleware::class,
            'permission' => PermissionMiddleware::class,
            'role_or_permission' => RoleOrPermissionMiddleware::class,
            'approved' => EnsureUserIsApproved::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->render(function (\Illuminate\Session\TokenMismatchException $e, \Illuminate\Http\Request $request) {
            if ($request->expectsJson() || $request->ajax()) {
                return response()->json(['message' => 'Your session expired. Please refresh the page and try again.'], 419);
            }

            $target = $request->headers->get('referer') ?: route('login');

            return redirect()->to($target)
                ->withInput($request->except(['_token', 'password', 'password_confirmation', 'current_password']))
                ->withErrors(['email' => 'Your session expired. Please try signing in again.'])
                ->with('status', 'Your session expired. Please try signing in again.');
        });
    })->create();
