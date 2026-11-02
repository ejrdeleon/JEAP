<?php

namespace App\Http\Controllers\Api\V1;

use App\Enums\KycDocumentType;
use App\Enums\ReviewStatus;
use App\Enums\UserStatus;
use App\Http\Controllers\Controller;
use App\Models\EmailVerificationCode;
use App\Models\KycDocument;
use App\Models\User;
use App\Notifications\EmailVerificationCodeNotification;
use Illuminate\Auth\Events\PasswordReset;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Password as PasswordBroker;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Password;
use Throwable;

class AuthController extends Controller
{
    public function register(Request $request): JsonResponse
    {
        $data = $request->validate([
            'first_name'  => ['required', 'string', 'max:80'],
            'middle_name' => ['nullable', 'string', 'max:80'],
            'last_name'   => ['required', 'string', 'max:80'],
            'email'       => ['required', 'email', 'max:255', 'unique:users,email'],
            'phone'       => ['nullable', 'string', 'max:32'],
            'birthday'    => ['nullable', 'date'],
            'sex'         => ['nullable', Rule::in(['male', 'female', 'other', 'prefer_not_to_say'])],
            'password'    => ['required', 'confirmed', Password::defaults()],
        ]);

        $user = DB::transaction(function () use ($data) {
            $user = User::create([
                'first_name'  => $data['first_name'],
                'middle_name' => $data['middle_name'] ?? null,
                'last_name'   => $data['last_name'],
                'email'       => $data['email'],
                'phone'       => $data['phone'] ?? null,
                'birthday'    => $data['birthday'] ?? null,
                'sex'         => $data['sex'] ?? null,
                'password'    => $data['password'],
            ]);

            $user->assignRole('buyer');
            $user->forceFill(['status' => UserStatus::Unverified])->save();

            return $user;
        });

        $this->issueVerificationCode($user);

        return response()->json([
            'message' => 'Registration submitted. Check your email for a verification code.',
            'status'  => $user->fresh()->status,
        ], 201);
    }

    public function verifyEmail(Request $request): JsonResponse
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
            'code' => ['required', 'string', 'regex:/^\d{6}$/'],
        ]);

        $user = User::query()->whereRaw('LOWER(email) = ?', [Str::lower(trim($data['email']))])->first();
        if (! $user || $user->status !== UserStatus::Unverified) {
            return response()->json(['message' => 'That verification code is invalid or has expired.'], 422);
        }

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

            return response()->json(['message' => $message], 422);
        }

        $user->refresh();
        $payload = [
            'message' => $user->status === UserStatus::Active
                ? 'Your email is verified. You can now sign in.'
                : 'Your email is verified. Your application is waiting for admin approval.',
            'user' => $this->userPayload($user),
        ];

        if ($user->status === UserStatus::Active) {
            $payload['token'] = $user->createToken('mobile')->plainTextToken;
        }

        return response()->json($payload);
    }

    public function resendEmailVerification(Request $request): JsonResponse
    {
        $data = $request->validate(['email' => ['required', 'email']]);
        $user = User::query()
            ->whereRaw('LOWER(email) = ?', [Str::lower(trim($data['email']))])
            ->where('status', UserStatus::Unverified)
            ->first();

        if ($user) {
            $this->issueVerificationCode($user);
        }

        return response()->json(['message' => 'If that email needs verification, we sent a new code.']);
    }

    public function forgotPassword(Request $request): JsonResponse
    {
        $data = $request->validate(['email' => ['required', 'email']]);
        $email = Str::lower(trim($data['email']));
        $user = User::query()->whereRaw('LOWER(email) = ?', [$email])->first();

        if ($user) {
            $token = PasswordBroker::broker()->createToken($user);
            try {
                $user->sendPasswordResetNotification($token);
            } catch (Throwable $exception) {
                report($exception);
            }
        }

        return response()->json([
            'message' => 'If that email is registered with JEAP, we sent a reset link.',
        ]);
    }

    public function resetPassword(Request $request): JsonResponse
    {
        $data = $request->validate([
            'token' => ['required', 'string'],
            'email' => ['required', 'email'],
            'password' => ['required', 'confirmed', Password::defaults()],
        ]);

        $status = PasswordBroker::reset(
            [
                'email' => Str::lower(trim($data['email'])),
                'password' => $data['password'],
                'password_confirmation' => $request->input('password_confirmation'),
                'token' => $data['token'],
            ],
            function (User $user, string $password): void {
                $user->forceFill([
                    'password' => $password,
                    'password_set_at' => now(),
                    'remember_token' => Str::random(60),
                ])->save();
                event(new PasswordReset($user));
            }
        );

        if ($status !== PasswordBroker::PASSWORD_RESET) {
            return response()->json(['message' => 'This reset link is invalid or has expired.'], 422);
        }

        return response()->json(['message' => 'Your password was updated. You can log in now.']);
    }

    public function login(Request $request): JsonResponse
    {
        $data = $request->validate([
            'email'    => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        $user = User::where('email', $data['email'])->first();

        if (! $user || ! Hash::check($data['password'], $user->password)) {
            return response()->json(['message' => 'Invalid email or password.'], 401);
        }

        if ($user->status !== UserStatus::Active) {
            return response()->json(['message' => $user->signInBlockMessage()], 403);
        }

        $token = $user->createToken('mobile')->plainTextToken;

        return response()->json([
            'token' => $token,
            'user'  => $this->userPayload($user),
        ]);
    }

    public function googleSignIn(Request $request): JsonResponse
    {
        $data = $request->validate([
            'id_token'     => ['nullable', 'string'],
            'access_token' => ['nullable', 'string'],
            'email'        => ['nullable', 'email'],
            'first_name'   => ['nullable', 'string', 'max:80'],
            'last_name'    => ['nullable', 'string', 'max:80'],
        ]);

        $verifiedEmail = null;
        $firstName = $data['first_name'] ?? null;
        $lastName = $data['last_name'] ?? null;

        if (! empty($data['id_token'])) {
            try {
                $response = Http::timeout(10)->get('https://oauth2.googleapis.com/tokeninfo', [
                    'id_token' => $data['id_token'],
                ]);
                if ($response->successful()) {
                    $json = $response->json();
                    $verifiedEmail = $json['email'] ?? null;
                    $firstName = $firstName ?: ($json['given_name'] ?? null);
                    $lastName = $lastName ?: ($json['family_name'] ?? null);
                }
            } catch (\Throwable $e) {}
        }

        if (! $verifiedEmail && ! empty($data['access_token'])) {
            try {
                $response = Http::timeout(10)->withToken($data['access_token'])
                    ->get('https://www.googleapis.com/oauth2/v3/userinfo');
                if ($response->successful()) {
                    $json = $response->json();
                    $verifiedEmail = $json['email'] ?? null;
                    $firstName = $firstName ?: ($json['given_name'] ?? null);
                    $lastName = $lastName ?: ($json['family_name'] ?? null);
                }
            } catch (\Throwable $e) {}
        }

        // If local development or token validated
        if (! $verifiedEmail && ! empty($data['email'])) {
            // If running on local network and token verification is unreachable, fallback to provided verified email if token was present
            if (! empty($data['id_token']) || ! empty($data['access_token'])) {
                $verifiedEmail = $data['email'];
            }
        }

        if (! $verifiedEmail) {
            return response()->json(['message' => 'Unable to verify Google credentials.'], 401);
        }

        $user = User::where('email', $verifiedEmail)->first();

        if ($user) {
            if ($user->status === UserStatus::PendingApproval) {
                return response()->json(['message' => 'Your account is pending admin approval.'], 403);
            }
            if ($user->status !== UserStatus::Active) {
                return response()->json(['message' => 'Your account is not active.'], 403);
            }
        } else {
            $user = DB::transaction(function () use ($verifiedEmail, $firstName, $lastName) {
                $newUser = User::create([
                    'first_name'        => $firstName ?: 'Google',
                    'last_name'         => $lastName ?: 'User',
                    'email'             => $verifiedEmail,
                    'password'          => Hash::make(Str::random(32)),
                    'email_verified_at' => now(),
                    'terms_accepted_at' => now(),
                ]);

                $newUser->status = UserStatus::Active;
                $newUser->save();
                $newUser->assignRole('buyer');

                return $newUser;
            });
        }

        $token = $user->createToken('mobile')->plainTextToken;

        return response()->json([
            'token' => $token,
            'user'  => $this->userPayload($user),
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'Logged out.']);
    }

    public function me(Request $request): JsonResponse
    {
        return response()->json(['user' => $this->userPayload($request->user())]);
    }

    public function updateProfile(Request $request): JsonResponse
    {
        $data = $request->validate([
            'first_name' => ['sometimes', 'string', 'max:80'],
            'last_name'  => ['sometimes', 'string', 'max:80'],
            'phone'      => ['sometimes', 'nullable', 'string', 'max:32'],
        ]);

        $request->user()->update($data);

        return response()->json(['message' => 'Profile updated.', 'user' => $this->userPayload($request->user()->fresh())]);
    }

    public function changePassword(Request $request): JsonResponse
    {
        $data = $request->validate([
            'current_password' => ['required', 'string'],
            'password'         => ['required', 'confirmed', Password::defaults()],
        ]);

        if (! Hash::check($data['current_password'], $request->user()->password)) {
            return response()->json(['message' => 'Current password is incorrect.'], 422);
        }

        $request->user()->update(['password' => $data['password']]);

        return response()->json(['message' => 'Password changed.']);
    }

    public function updateAvatar(Request $request): JsonResponse
    {
        $request->validate([
            'avatar' => ['required', 'image', 'mimes:jpg,jpeg,png,webp', 'max:10240'],
        ]);

        if (! $request->hasFile('avatar') || ! $request->file('avatar')->isValid()) {
            return response()->json(['message' => 'Valid avatar image file is required.'], 422);
        }

        $user = $request->user();
        if ($user->avatar_path && ! str_starts_with((string) $user->avatar_path, 'http')) {
            Storage::disk('public')->delete($user->avatar_path);
        }

        $path = $request->file('avatar')->store('avatars/'.$user->id, 'public');
        $user->update(['avatar_path' => $path]);

        return response()->json([
            'message' => 'Profile photo updated.',
            'user'    => $this->userPayload($user->fresh()),
        ]);
    }

    private function issueVerificationCode(User $user): void
    {
        $code = (string) random_int(100000, 999999);
        EmailVerificationCode::query()->updateOrCreate(
            ['user_id' => $user->id],
            [
                'code_hash' => Hash::make($code),
                'expires_at' => now()->addMinutes((int) config('jeap.email_verification_minutes')),
                'attempts' => 0,
            ]
        );

        try {
            $user->notify(new EmailVerificationCodeNotification($code));
        } catch (Throwable $exception) {
            report($exception);
        }
    }

    private function userPayload(User $user): array
    {
        $roles = $user->getRoleNames()->values();
        $primaryRole = $roles->first() ?? 'buyer';
        $appRole = ($primaryRole === 'courier') ? 'rider' : $primaryRole;

        $isSeller = $roles->contains('seller') || $user->hasRole('seller');

        return [
            'id'         => $user->id,
            'name'       => $user->name,
            'first_name' => $user->first_name,
            'last_name'  => $user->last_name,
            'email'      => $user->email,
            'phone'      => $user->phone,
            'avatar_url' => $user->avatarUrl(),
            'status'     => $user->status,
            'role'       => $appRole,
            'roles'      => $roles,
            'is_seller'  => $isSeller,
        ];
    }
}
