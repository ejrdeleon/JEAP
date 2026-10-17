<?php

namespace App\Http\Middleware;

use App\Enums\UserStatus;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureUserIsApproved
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if ($user && $user->status !== UserStatus::Active) {
            auth()->logout();

            if ($request->hasSession()) {
                $request->session()->invalidate();
                $request->session()->regenerateToken();
            }

            if ($request->expectsJson()) {
                abort(403, 'Your account is not active.');
            }

            return redirect()
                ->route('login')
                ->withErrors([
                    'email' => $user->status === UserStatus::PendingApproval
                        ? 'Your account is pending approval. You cannot sign in yet.'
                        : 'Your account is not active.',
                ]);
        }

        return $next($request);
    }
}
