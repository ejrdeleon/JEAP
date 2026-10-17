<?php

namespace App\Http\Controllers\Auth;

use App\Enums\UserStatus;
use App\Http\Controllers\Controller;
use App\Models\Cart;
use App\Models\User;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;

class LoginController extends Controller
{
    public function create(): View
    {
        return view('auth.login');
    }

    public function store(Request $request): RedirectResponse
    {
        $cartSessionId = $request->session()->getId();
        $credentials = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        if (! Auth::attempt($credentials, $request->boolean('remember'))) {
            return back()->withErrors([
                'email' => 'These credentials do not match our records.',
            ])->onlyInput('email');
        }

        $user = Auth::user();

        if ($user->status !== UserStatus::Active) {
            Auth::logout();
            $request->session()->invalidate();
            $request->session()->regenerateToken();

            $message = $user->status === UserStatus::PendingApproval
                ? 'Your account is pending approval. You cannot sign in yet.'
                : 'Your account is not active.';

            return back()->withErrors(['email' => $message])->onlyInput('email');
        }

        return $this->completeSuccessfulLogin($request, $user, $cartSessionId);
    }

    public function completeSuccessfulLogin(Request $request, User $user, string $cartSessionId): RedirectResponse
    {
        if ($user->hasRole('buyer')) {
            $this->mergeGuestCart($cartSessionId, $user);
        }

        $request->session()->regenerate();

        return redirect()->to($this->safeHome($request, $user));
    }

    public function destroy(Request $request): RedirectResponse
    {
        Auth::logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect()->route('home');
    }

    private function safeHome(Request $request, $user): string
    {
        $home = $this->homeFor($user);
        $intended = $request->session()->pull('url.intended');

        if ($user->hasAnyRole(['admin', 'super-admin', 'seller', 'courier', 'logistics'])) {
            return $home;
        }

        if (! is_string($intended) || $intended === '') {
            return $home;
        }

        $parts = parse_url($intended);
        if ($parts === false || str_starts_with($intended, '//')) {
            return $home;
        }

        if (isset($parts['host']) && strcasecmp($parts['host'], $request->getHost()) !== 0) {
            return $home;
        }

        if (isset($parts['scheme']) && ! in_array(strtolower($parts['scheme']), ['http', 'https'], true)) {
            return $home;
        }

        $path = $parts['path'] ?? $intended;
        foreach (['/admin', '/super-admin', '/seller', '/courier', '/logistics'] as $prefix) {
            if ($path === $prefix || str_starts_with($path, $prefix.'/')) {
                return $home;
            }
        }

        return $intended;
    }

    private function homeFor($user): string
    {
        if ($user->hasRole('super-admin')) {
            return route('super-admin.dashboard');
        }
        if ($user->hasRole('admin')) {
            return route('admin.dashboard');
        }
        if ($user->hasRole('seller')) {
            return route('seller.dashboard');
        }
        if ($user->hasRole('courier')) {
            return route('courier.dashboard');
        }
        if ($user->hasRole('logistics')) {
            return route('logistics.dashboard');
        }

        return route('buyer.home');
    }

    private function mergeGuestCart(string $sessionId, User $user): void
    {
        DB::transaction(function () use ($sessionId, $user): void {
            $guestCart = Cart::query()->whereNull('user_id')->where('session_id', $sessionId)
                ->lockForUpdate()->first();
            if (! $guestCart) {
                return;
            }

            $userCart = Cart::query()->where('user_id', $user->id)->lockForUpdate()->first();
            if (! $userCart) {
                $guestCart->update(['user_id' => $user->id]);

                return;
            }

            foreach ($guestCart->items as $guestItem) {
                $userItem = $userCart->items()->where('product_variant_id', $guestItem->product_variant_id)->first();
                if ($userItem) {
                    $userItem->increment('quantity', $guestItem->quantity);
                    $guestItem->delete();
                } else {
                    $guestItem->update(['cart_id' => $userCart->id]);
                }
            }

            $guestCart->delete();
        });
    }
}
