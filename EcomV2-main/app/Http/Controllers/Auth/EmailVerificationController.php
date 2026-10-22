<?php

namespace App\Http\Controllers\Auth;

use App\Enums\UserStatus;
use App\Http\Controllers\Controller;
use App\Models\EmailVerificationCode;
use App\Models\User;
use App\Notifications\EmailVerificationCodeNotification;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\View\View;
use Throwable;

class EmailVerificationController extends Controller
{
    public function show(Request $request): View|RedirectResponse
    {
        $user = User::query()->find($request->session()->get('email_verification_user_id'));
        abort_unless($user && $user->status === UserStatus::Unverified, 404);

        return view('auth.verify-email', compact('user'));
    }

    public function verify(Request $request): RedirectResponse
    {
        $data = $request->validate(['code' => ['required', 'string', 'regex:/^\d{6}$/']]);
        $user = User::query()->find($request->session()->get('email_verification_user_id'));
        abort_unless($user && $user->status === UserStatus::Unverified, 404);

        $result = DB::transaction(function () use ($user, $data): string {
            $code = EmailVerificationCode::query()->where('user_id', $user->id)->lockForUpdate()->first();
            if (! $code || $code->expires_at->isPast()) {
                return 'expired';
            }
            if ($code->attempts >= 5) {
                return 'locked';
            }
            if (! Hash::check($data['code'], $code->code_hash)) {
                $code->increment('attempts');

                return 'invalid';
            }

            $user->forceFill([
                'email_verified_at' => now(),
                'status' => $user->hasRole('buyer') ? UserStatus::Active : UserStatus::PendingApproval,
            ])->save();
            $code->delete();

            return 'verified';
        });

        if ($result !== 'verified') {
            $message = match ($result) {
                'expired' => 'That code has expired. Request a new code to continue.',
                'locked' => 'Too many incorrect codes. Request a new code to try again.',
                default => 'That code is incorrect. Please check it and try again.',
            };

            return to_route('email.verify.show')->withErrors(['code' => $message]);
        }

        $request->session()->forget(['email_verification_user_id', 'email_verification_preview']);
        $message = $user->hasRole('buyer')
            ? 'Your email is verified. You can now sign in.'
            : 'Your email is verified. Your application is waiting for admin approval.';

        return to_route('login')->with('status', $message);
    }

    public function resend(Request $request): RedirectResponse
    {
        $user = User::query()->find($request->session()->get('email_verification_user_id'));
        abort_unless($user && $user->status === UserStatus::Unverified, 404);

        $code = (string) random_int(100000, 999999);
        EmailVerificationCode::query()->updateOrCreate(
            ['user_id' => $user->id],
            ['code_hash' => Hash::make($code), 'expires_at' => now()->addMinutes((int) config('jeap.email_verification_minutes')), 'attempts' => 0],
        );
        if (config('mail.default') === 'log') {
            $request->session()->put('email_verification_preview', $code);
        }
        try {
            $user->notify(new EmailVerificationCodeNotification($code));
        } catch (Throwable $exception) {
            report($exception);

            return to_route('email.verify.show')->with('mail_error', 'The verification email could not be sent. Please try again shortly.');
        }

        return to_route('email.verify.show')->with('status', 'A new verification code was sent. Your previous code has expired.');
    }
}
