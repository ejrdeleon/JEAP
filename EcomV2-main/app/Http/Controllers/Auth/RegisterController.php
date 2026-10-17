<?php

namespace App\Http\Controllers\Auth;

use App\Enums\KycDocumentType;
use App\Enums\ReviewStatus;
use App\Http\Controllers\Controller;
use App\Models\CourierProfile;
use App\Models\KycDocument;
use App\Models\LogisticsProfile;
use App\Models\SellerProfile;
use App\Models\User;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Password;
use Illuminate\View\View;

class RegisterController extends Controller
{
    public function create(): View
    {
        return view('auth.register');
    }

    public function createSeller(): View
    {
        return view('auth.register-seller');
    }

    public function createRider(): View
    {
        return view('auth.register-rider');
    }

    public function createLogistics(): View
    {
        return view('auth.register-logistics');
    }

    public function store(Request $request): RedirectResponse
    {
        return $this->registerRole($request, 'buyer');
    }

    public function storeSeller(Request $request): RedirectResponse
    {
        return $this->registerRole($request, 'seller');
    }

    public function storeRider(Request $request): RedirectResponse
    {
        return $this->registerRole($request, 'courier');
    }

    public function storeLogistics(Request $request): RedirectResponse
    {
        return $this->registerRole($request, 'logistics');
    }

    public function pending(): View
    {
        return view('auth.pending');
    }

    private function registerRole(Request $request, string $role): RedirectResponse
    {
        $request->merge($this->splitName($request->input('name'), $request->input('first_name'), $request->input('last_name')));
        $request->merge(['role' => $role]);

        $data = $request->validate([
            'role' => ['required', Rule::in(['buyer', 'seller', 'courier', 'logistics'])],
            'first_name' => ['required', 'string', 'max:80'],
            'middle_name' => ['nullable', 'string', 'max:80'],
            'last_name' => ['required', 'string', 'max:80'],
            'sex' => ['nullable', Rule::in(['male', 'female', 'other', 'prefer_not_to_say'])],
            'email' => ['required', 'email', 'max:255', 'unique:users,email'],
            'phone' => ['nullable', 'string', 'max:32'],
            'birthday' => ['nullable', 'date'],
            'password' => ['required', 'confirmed', Password::defaults()],
            'business_name' => ['required_if:role,seller,logistics', 'nullable', 'string', 'max:160'],
            'vehicle_type' => ['required_if:role,courier', 'nullable', 'string', 'max:80'],
            'plate_number' => ['required_if:role,courier', 'nullable', 'string', 'max:32'],
            'kyc' => [$role === 'buyer' ? 'nullable' : 'required', 'file', 'mimes:jpg,jpeg,png,pdf', 'max:5120'],
        ]);

        $user = DB::transaction(function () use ($data, $request) {
            $user = User::create([
                'first_name' => $data['first_name'],
                'middle_name' => $data['middle_name'] ?? null,
                'last_name' => $data['last_name'],
                'sex' => $data['sex'] ?? null,
                'email' => $data['email'],
                'phone' => $data['phone'] ?? null,
                'birthday' => $data['birthday'] ?? null,
                'password' => $data['password'],
            ]);

            $user->assignRole($data['role']);

            if ($data['role'] === 'seller') {
                SellerProfile::create([
                    'user_id' => $user->id,
                    'business_name' => $data['business_name'],
                ]);
            }

            if ($data['role'] === 'courier') {
                CourierProfile::create([
                    'user_id' => $user->id,
                    'vehicle_type' => $data['vehicle_type'] ?? null,
                    'plate_number' => $data['plate_number'] ?? null,
                ]);
            }

            if ($data['role'] === 'logistics') {
                LogisticsProfile::create([
                    'user_id' => $user->id,
                    'hub_business_name' => $data['business_name'],
                ]);
            }

            if ($request->hasFile('kyc')) {
                $path = $request->file('kyc')->store('kyc/'.$user->id, 'local');
                KycDocument::create([
                    'user_id' => $user->id,
                    'type' => match ($data['role']) {
                        'seller' => KycDocumentType::BusinessPermit,
                        'courier' => KycDocumentType::DriversLicense,
                        'logistics' => KycDocumentType::BusinessPermit,
                        default => KycDocumentType::Id,
                    },
                    'file_path' => $path,
                    'review_status' => ReviewStatus::Pending,
                ]);
            }

            return $user;
        });

        $label = match ($role) {
            'seller' => 'Seller account',
            'courier' => 'Rider account',
            'logistics' => 'Sorting center account',
            default => 'Account',
        };

        return redirect()
            ->route('register.pending')
            ->with('status', $label.' created for '.$user->email.'. Wait for approval before signing in.');
    }

    private function splitName(?string $name, ?string $first, ?string $last): array
    {
        if ($first && $last) {
            return ['first_name' => $first, 'last_name' => $last];
        }

        $parts = preg_split('/\s+/', trim((string) $name), 2) ?: [];

        return [
            'first_name' => $parts[0] ?? 'Buyer',
            'last_name' => $parts[1] ?? ($parts[0] ?? 'Buyer'),
        ];
    }
}
