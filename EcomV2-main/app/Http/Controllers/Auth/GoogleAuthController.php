<?php

namespace App\Http\Controllers\Auth;

use App\Enums\UserStatus;
use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Database\QueryException;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Laravel\Socialite\Contracts\User as SocialiteUser;
use Laravel\Socialite\Facades\Socialite;
use Laravel\Socialite\Two\InvalidStateException;
use Throwable;

class GoogleAuthController extends Controller
{
    public function redirect(Request $request): RedirectResponse
    {
        if (! config('services.google.client_id') || ! config('services.google.client_secret')) {
            return $this->returnToAuthPage($request, 'Google sign-in is not configured yet.');
        }

        $source = $request->query('from') === 'register' ? 'register' : 'login';
        $request->session()->put('auth.google.source', $source);

        // Keep Socialite's state validation enabled; never use stateless() here.
        return Socialite::driver('google')->scopes(['openid', 'email', 'profile'])->redirect();
    }

    public function callback(Request $request, LoginController $login): RedirectResponse
    {
        if ($request->filled('error')) {
            return $this->returnToAuthPage($request, 'Google sign-in was cancelled. You can try again or use your email and password.');
        }

        try {
            /** @var SocialiteUser $google */
            $google = Socialite::driver('google')->user();
        } catch (InvalidStateException) {
            return $this->returnToAuthPage($request, 'Google sign-in could not be verified. Please try again.');
        } catch (Throwable) {
            return $this->returnToAuthPage($request, 'Google sign-in failed. Please try again.');
        }

        $email = strtolower(trim((string) $google->getEmail()));
        $googleId = trim((string) $google->getId());
        $profile = $google->getRaw();
        $verified = filter_var($profile['email_verified'] ?? $profile['verified_email'] ?? false, FILTER_VALIDATE_BOOLEAN);

        if ($email === '' || $googleId === '' || ! $verified) {
            return $this->returnToAuthPage($request, 'Google did not provide a verified email address. Please use a verified Google account or register with email.');
        }

        try {
            $user = DB::transaction(function () use ($google, $googleId, $email): User {
                $user = User::query()->where('google_id', $googleId)->lockForUpdate()->first();

                if (! $user) {
                    $user = User::query()->whereRaw('LOWER(email) = ?', [$email])->lockForUpdate()->first();

                    if ($user) {
                        if ($user->google_id !== null && ! hash_equals((string) $user->google_id, $googleId)) {
                            throw new GoogleAccountConflict('This email is already linked to another Google account.');
                        }

                        $user->forceFill([
                            'google_id' => $googleId,
                            'email_verified_at' => $user->email_verified_at ?? now(),
                        ])->save();
                    } else {
                        $fullName = trim((string) $google->getName());
                        $nameParts = preg_split('/\s+/', $fullName, 2) ?: [];

                        $user = User::create([
                            'first_name' => $nameParts[0] ?? 'Google',
                            'last_name' => $nameParts[1] ?? ($nameParts[0] ?? 'Buyer'),
                            'email' => $email,
                            'password' => Hash::make(Str::random(64)),
                            'email_verified_at' => now(),
                        ]);
                        $user->forceFill(['google_id' => $googleId])->save();
                        $user->assignRole('buyer');
                    }
                }

                return $user;
            });
        } catch (GoogleAccountConflict $exception) {
            return $this->returnToAuthPage($request, $exception->getMessage());
        } catch (QueryException) {
            // A concurrent callback can win the unique provider-ID constraint. Re-read safely.
            $user = User::query()->where('google_id', $googleId)->first();
            if (! $user || strcasecmp($user->email, $email) !== 0) {
                return $this->returnToAuthPage($request, 'This Google account could not be linked safely. Please contact support.');
            }
        }

        if ($user->status !== UserStatus::Active) {
            $message = $user->status === UserStatus::PendingApproval
                ? 'Your account is pending approval. You cannot sign in yet.'
                : 'Your account is not active.';

            return $this->returnToAuthPage($request, $message);
        }

        $request->session()->forget('auth.google.source');
        $cartSessionId = $request->session()->getId();
        Auth::login($user);

        return $login->completeSuccessfulLogin($request, $user, $cartSessionId);
    }

    private function returnToAuthPage(Request $request, string $message): RedirectResponse
    {
        $source = $request->session()->pull('auth.google.source', 'login');
        $route = $source === 'register' ? 'register' : 'login';

        return redirect()->route($route)->withErrors(['google' => $message]);
    }
}

class GoogleAccountConflict extends \RuntimeException {}
