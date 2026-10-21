<?php

namespace App\Http\Controllers\Logistics;

use App\Enums\KycDocumentType;
use App\Enums\ReviewStatus;
use App\Enums\UserStatus;
use App\Http\Controllers\Controller;
use App\Models\CourierProfile;
use App\Models\KycDocument;
use App\Models\LogisticsProfile;
use App\Models\RiderActivationToken;
use App\Models\User;
use App\Notifications\RiderActivationNotification;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Password;
use Illuminate\View\View;
use Throwable;

class RiderController extends Controller
{
    public function index(Request $request): View
    {
        $company = $this->companyFor($request);
        $riders = User::query()->whereHas('courierProfile', fn ($query) => $query->where('logistics_profile_id', $company->id))
            ->with('courierProfile', 'kycDocuments')
            ->latest()->paginate(20);

        return view('logistics.riders', compact('company', 'riders'));
    }

    public function store(Request $request): RedirectResponse
    {
        $company = $this->companyFor($request);
        $request->merge([
            'email' => Str::lower(trim((string) $request->input('email'))),
            'phone' => $this->normalizePhone((string) $request->input('phone')),
            'license_number' => Str::upper(trim((string) $request->input('license_number'))),
            'plate_number' => Str::upper(preg_replace('/\s+/', '', trim((string) $request->input('plate_number')))),
        ]);
        $data = $request->validate([
            'first_name' => ['required', 'string', 'min:2', 'max:50', 'regex:/^[\pL\pM .\'-]+$/u'],
            'last_name' => ['required', 'string', 'min:2', 'max:50', 'regex:/^[\pL\pM .\'-]+$/u'],
            'birthday' => ['required', 'date', 'before_or_equal:'.now()->subYears(18)->toDateString()],
            'email' => ['required', 'email', 'max:255', 'unique:users,email'],
            'phone' => ['required', 'regex:/^\+639\d{9}$/', 'unique:users,phone'],
            'license_number' => ['required', 'regex:/^[A-Z]\d{2}-\d{2}-\d{6}$/', 'unique:courier_profiles,license_number'],
            'license_expires_at' => ['required', 'date', 'after_or_equal:today'],
            'vehicle_type' => ['required', Rule::in(['motorcycle', 'car', 'van'])],
            'plate_number' => ['required', 'string', 'max:16', 'unique:courier_profiles,plate_number'],
            'documents.drivers_license' => ['required', 'file', 'mimes:jpg,jpeg,png,pdf', 'max:5120'],
            'documents.vehicle_registration' => ['required', 'file', 'mimes:jpg,jpeg,png,pdf', 'max:5120'],
        ]);

        $rider = DB::transaction(function () use ($request, $data, $company): User {
            $user = User::query()->create([
                'first_name' => $data['first_name'],
                'last_name' => $data['last_name'],
                'email' => $data['email'],
                'phone' => $data['phone'],
                'birthday' => $data['birthday'],
                'password' => Str::random(64),
            ]);
            $user->forceFill(['status' => UserStatus::PendingActivation])->save();
            $user->assignRole('courier');

            CourierProfile::query()->create([
                'user_id' => $user->id,
                'logistics_profile_id' => $company->id,
                'vehicle_type' => $data['vehicle_type'],
                'plate_number' => $data['plate_number'],
                'license_number' => $data['license_number'],
                'license_expires_at' => $data['license_expires_at'],
            ]);

            foreach ([
                'drivers_license' => KycDocumentType::DriversLicense,
                'vehicle_registration' => KycDocumentType::VehicleRegistration,
            ] as $key => $type) {
                $path = $request->file('documents.'.$key)->store('kyc/'.$user->id, 'local');
                KycDocument::query()->create([
                    'user_id' => $user->id,
                    'type' => $type,
                    'file_path' => $path,
                    'review_status' => ReviewStatus::Pending,
                ]);
            }

            return $user;
        });

        try {
            $this->sendActivation($rider);
        } catch (Throwable $exception) {
            report($exception);

            return back()->withInput($request->except('documents'))->withErrors(['email' => 'The rider was created, but the activation email could not be sent. Use Resend activation from the rider list.']);
        }

        return to_route('logistics.riders')->with('status', 'Rider added. An account activation link was emailed to '.$rider->email.'.');
    }

    public function resend(Request $request, User $user): RedirectResponse
    {
        $company = $this->companyFor($request);
        abort_unless($user->hasRole('courier') && $user->courierProfile?->logistics_profile_id === $company->id, 404);
        abort_unless($user->status === UserStatus::PendingActivation, 409);

        try {
            $this->sendActivation($user);
        } catch (Throwable $exception) {
            report($exception);

            return back()->withErrors(['email' => 'The activation email could not be sent. Please try again shortly.']);
        }

        return back()->with('status', 'A new activation link was sent. The previous link is no longer valid.');
    }

    public function showActivation(User $user, string $token): View
    {
        $this->assertValidActivation($user, $token);

        return view('auth.activate-rider', compact('user', 'token'));
    }

    public function activate(Request $request, User $user, string $token): RedirectResponse
    {
        $data = $request->validate([
            'password' => ['required', 'confirmed', Password::min(8)->mixedCase()->numbers()->symbols()],
        ]);

        DB::transaction(function () use ($user, $token, $data): void {
            $activation = RiderActivationToken::query()->where('user_id', $user->id)->lockForUpdate()->first();
            abort_unless(
                $user->status === UserStatus::PendingActivation
                    && $activation
                    && ! $activation->expires_at->isPast()
                    && Hash::check($token, $activation->token_hash),
                404
            );

            $user->forceFill([
                'password' => $data['password'],
                'email_verified_at' => now(),
                'status' => UserStatus::Active,
            ])->save();
            $activation->delete();
        });

        return to_route('login')->with('status', 'Your rider account is active. You can now sign in.');
    }

    private function sendActivation(User $user): void
    {
        $token = Str::random(64);
        RiderActivationToken::query()->updateOrCreate(
            ['user_id' => $user->id],
            ['token_hash' => Hash::make($token), 'expires_at' => now()->addHours(24)],
        );
        $url = route('rider.activate.show', ['user' => $user->id, 'token' => $token]);
        $user->notify(new RiderActivationNotification($url));
    }

    private function assertValidActivation(User $user, string $token): void
    {
        $activation = RiderActivationToken::query()->where('user_id', $user->id)->first();
        abort_unless(
            $user->hasRole('courier')
                && $user->status === UserStatus::PendingActivation
                && $activation
                && ! $activation->expires_at->isPast()
                && Hash::check($token, $activation->token_hash),
            404
        );
    }

    private function companyFor(Request $request): LogisticsProfile
    {
        $company = $request->user()->logisticsProfile()->first();
        if ($company) {
            return $company;
        }

        abort_unless($request->user()->hasRole('super-admin'), 404);

        return LogisticsProfile::query()->firstOrFail();
    }

    private function normalizePhone(string $phone): string
    {
        $phone = preg_replace('/\s+/', '', trim($phone));

        return preg_match('/^09\d{9}$/', $phone) ? '+63'.substr($phone, 1) : $phone;
    }
}
