<?php

namespace App\Http\Controllers\Api\V1;

use App\Enums\KycDocumentType;
use App\Enums\ReviewStatus;
use App\Enums\UserStatus;
use App\Http\Controllers\Controller;
use App\Models\KycDocument;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Password;

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

            return $user;
        });

        return response()->json([
            'message' => 'Registration submitted. Wait for admin approval before signing in.',
            'status'  => $user->status,
        ], 201);
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

    private function userPayload(User $user): array
    {
        return [
            'id'         => $user->id,
            'name'       => $user->name,
            'first_name' => $user->first_name,
            'last_name'  => $user->last_name,
            'email'      => $user->email,
            'phone'      => $user->phone,
            'status'     => $user->status,
            'roles'      => $user->getRoleNames()->values(),
        ];
    }
}
