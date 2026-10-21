<?php

namespace App\Http\Controllers\Auth;

use App\Enums\KycDocumentType;
use App\Enums\ReviewStatus;
use App\Enums\UserStatus;
use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\CourierProfile;
use App\Models\EmailVerificationCode;
use App\Models\KycDocument;
use App\Models\LogisticsProfile;
use App\Models\SellerProfile;
use App\Models\User;
use App\Notifications\EmailVerificationCodeNotification;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Password;
use Illuminate\View\View;
use Throwable;

class RegisterController extends Controller
{
    public function create(): View
    {
        return view('auth.register');
    }

    public function createSeller(): View
    {
        return view('auth.register-seller', [
            'categories' => Category::query()->where('is_active', true)->where('is_line_of_business', true)->orderBy('sort_order')->get(),
        ]);
    }

    public function createRider(): RedirectResponse
    {
        return to_route('login')->with('status', 'Rider accounts are created by an approved logistics company.');
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
        return to_route('login')->with('status', 'Rider accounts are created by an approved logistics company.');
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
        $email = Str::lower(trim((string) $request->input('email')));
        $phone = preg_replace('/\s+/', '', trim((string) $request->input('phone')));
        $tin = preg_replace('/\D+/', '', (string) $request->input('tin'));
        $secRegistration = Str::upper(trim((string) $request->input('sec_registration_number')));
        if (preg_match('/^09\d{9}$/', $phone)) {
            $phone = '+63'.substr($phone, 1);
        }
        $businessNameRules = ['required_if:role,seller,logistics', 'nullable', 'string', $role === 'seller' ? 'max:30' : 'max:160'];
        if ($role === 'seller') {
            $businessNameRules[] = 'min:3';
            $businessNameRules[] = Rule::unique('seller_profiles', 'business_name');
        } elseif ($role === 'logistics') {
            $businessNameRules[] = Rule::unique('logistics_profiles', 'hub_business_name');
        }
        $request->merge([
            'role' => $role,
            'email' => $email,
            'phone' => $phone,
            'tin' => $tin,
            'sec_registration_number' => $secRegistration,
        ]);

        $this->replaceUnverifiedAccount($email, is_string($phone) ? $phone : null);

        $data = $request->validate([
            'role' => ['required', Rule::in(['buyer', 'seller', 'courier', 'logistics'])],
            'first_name' => ['required', 'string', 'min:2', 'max:50', 'regex:/^[\pL\pM .\'-]+$/u'],
            'middle_name' => ['nullable', 'string', 'max:50', 'regex:/^[\pL\pM .\'-]+$/u'],
            'last_name' => ['required', 'string', 'min:2', 'max:50', 'regex:/^[\pL\pM .\'-]+$/u'],
            'sex' => ['nullable', Rule::in(['male', 'female', 'other', 'prefer_not_to_say'])],
            'email' => ['required', 'email', 'max:255', 'unique:users,email'],
            'phone' => ['required', 'regex:/^\+639\d{9}$/', 'unique:users,phone'],
            'birthday' => [$role === 'buyer' ? 'required' : 'nullable', 'date', 'before_or_equal:'.now()->subYears(18)->toDateString()],
            'password' => ['required', 'confirmed', Password::min(8)->mixedCase()->numbers()->symbols()],
            'terms' => ['accepted'],
            'business_name' => $businessNameRules,
            'shop_category_id' => ['required_if:role,seller', 'nullable', 'integer', 'exists:categories,id'],
            'seller_type' => ['required_if:role,seller', 'nullable', Rule::in(['individual', 'sole_proprietorship', 'corporation'])],
            'tin' => ['required_if:role,seller,logistics', 'nullable', 'regex:/^\d{12}$/', Rule::unique('seller_profiles', 'tin'), Rule::unique('logistics_profiles', 'tin')],
            'sec_registration_number' => ['required_if:role,logistics', 'required_if:seller_type,corporation', 'nullable', 'regex:/^[A-Z]{2}\d{9}$/', Rule::unique('logistics_profiles', 'sec_registration_number'), Rule::unique('seller_profiles', 'sec_registration_number')],
            'region_name' => ['required', 'string', 'max:120'],
            'province_name' => ['nullable', 'string', 'max:120'],
            'city_name' => ['required', 'string', 'max:120'],
            'barangay_name' => ['nullable', 'string', 'max:120'],
            'street_line' => ['required', 'string', 'max:255'],
            'postal_code' => ['required', 'regex:/^\d{4}$/'],
            'region_code' => ['nullable', 'regex:/^\d{1,16}$/'],
            'province_code' => ['nullable', 'regex:/^\d{1,16}$/'],
            'city_code' => ['nullable', 'regex:/^\d{1,16}$/'],
            'barangay_code' => ['nullable', 'regex:/^\d{1,16}$/'],
            'country_code' => ['nullable', 'string', 'size:2', 'alpha'],
            'country_name' => ['nullable', 'string', 'max:120'],
            'service_areas' => ['required_if:role,logistics', 'array', 'min:1'],
            'service_areas.*' => ['string', 'max:120'],
            'contact_position' => ['required_if:role,logistics', 'nullable', 'string', 'max:120'],
            'vehicle_type' => ['required_if:role,courier', 'nullable', 'string', 'max:80'],
            'plate_number' => ['required_if:role,courier', 'nullable', 'string', 'max:32'],
            'documents' => [$role === 'buyer' ? 'nullable' : 'required', 'array'],
            'documents.government_id' => [$role === 'seller' ? 'required' : 'nullable', 'file', 'mimes:jpg,jpeg,png,pdf', 'max:5120'],
            'documents.dti_certificate' => [$role === 'seller' && $request->input('seller_type') === 'sole_proprietorship' ? 'required' : 'nullable', 'file', 'mimes:jpg,jpeg,png,pdf', 'max:5120'],
            'documents.sec_certificate' => [$role === 'seller' && $request->input('seller_type') === 'corporation' || $role === 'logistics' ? 'required' : 'nullable', 'file', 'mimes:jpg,jpeg,png,pdf', 'max:5120'],
            'documents.bir_2303' => [$role === 'seller' && in_array($request->input('seller_type'), ['sole_proprietorship', 'corporation'], true) || $role === 'logistics' ? 'required' : 'nullable', 'file', 'mimes:jpg,jpeg,png,pdf', 'max:5120'],
            'documents.business_permit' => [$role === 'logistics' ? 'required' : 'nullable', 'file', 'mimes:jpg,jpeg,png,pdf', 'max:5120'],
            'documents.representative_id' => [$role === 'logistics' ? 'required' : 'nullable', 'file', 'mimes:jpg,jpeg,png,pdf', 'max:5120'],
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
                'terms_accepted_at' => now(),
                'password' => $data['password'],
            ]);
            $user->forceFill(['status' => UserStatus::Unverified])->save();

            $user->assignRole($data['role']);

            if ($data['role'] === 'buyer') {
                $this->saveAddress($user, $user, $data, 'Home', true);
            }

            if ($data['role'] === 'seller') {
                $profile = SellerProfile::create([
                    'user_id' => $user->id,
                    'business_name' => $data['business_name'],
                    'line_of_business_category_id' => $data['shop_category_id'],
                    'seller_type' => $data['seller_type'],
                    'tin' => $data['tin'],
                    'sec_registration_number' => $data['sec_registration_number'] ?? null,
                ]);
                $this->saveAddress($profile, $user, $data, 'Business');
            }

            if ($data['role'] === 'courier') {
                CourierProfile::create([
                    'user_id' => $user->id,
                    'vehicle_type' => $data['vehicle_type'] ?? null,
                    'plate_number' => $data['plate_number'] ?? null,
                ]);
            }

            if ($data['role'] === 'logistics') {
                $profile = LogisticsProfile::create([
                    'user_id' => $user->id,
                    'hub_business_name' => $data['business_name'],
                    'sec_registration_number' => $data['sec_registration_number'],
                    'tin' => $data['tin'],
                    'contact_position' => $data['contact_position'],
                    'service_areas' => $data['service_areas'],
                ]);
                $this->saveAddress($profile, $user, $data, 'Business');
            }

            $documentTypes = [
                'government_id' => KycDocumentType::Id,
                'dti_certificate' => KycDocumentType::DtiCertificate,
                'sec_certificate' => KycDocumentType::SecCertificate,
                'bir_2303' => KycDocumentType::Bir2303,
                'business_permit' => KycDocumentType::MayorsPermit,
                'representative_id' => KycDocumentType::RepresentativeId,
            ];
            foreach ($request->file('documents', []) as $key => $file) {
                if (! isset($documentTypes[$key])) {
                    continue;
                }
                $path = $file->store('kyc/'.$user->id, 'local');
                KycDocument::create([
                    'user_id' => $user->id,
                    'type' => $documentTypes[$key],
                    'file_path' => $path,
                    'review_status' => ReviewStatus::Pending,
                ]);
            }

            return $user;
        });

        $code = (string) random_int(100000, 999999);
        EmailVerificationCode::query()->updateOrCreate(
            ['user_id' => $user->id],
            ['code_hash' => Hash::make($code), 'expires_at' => now()->addMinutes(5), 'attempts' => 0],
        );
        $request->session()->put('email_verification_user_id', $user->id);
        if (config('mail.default') === 'log') {
            $request->session()->put('email_verification_preview', $code);
        }
        try {
            $user->notify(new EmailVerificationCodeNotification($code));
        } catch (Throwable $exception) {
            report($exception);

            return to_route('email.verify.show')->with('mail_error', 'Your account was created, but the code could not be sent. Please use Resend code to try again.');
        }

        return to_route('email.verify.show')->with('status', 'A 6-digit verification code was sent to '.$user->email.'.');
    }

    private function replaceUnverifiedAccount(string $email, ?string $phone): void
    {
        User::query()
            ->where('status', UserStatus::Unverified)
            ->where(function ($query) use ($email, $phone): void {
                $query->where('email', $email);
                if (is_string($phone) && $phone !== '') {
                    $query->orWhere('phone', $phone);
                }
            })
            ->get()
            ->each(function (User $user): void {
                $user->addresses()->delete();
                $user->kycDocuments()->each(function (KycDocument $document): void {
                    if ($document->file_path) {
                        foreach (['local', 'public'] as $disk) {
                            if (Storage::disk($disk)->exists($document->file_path)) {
                                Storage::disk($disk)->delete($document->file_path);
                            }
                        }
                    }
                    $document->delete();
                });
                $user->sellerProfile?->addresses()->delete();
                $user->sellerProfile()->delete();
                $user->logisticsProfile?->addresses()->delete();
                $user->logisticsProfile()->delete();
                $user->courierProfile()->delete();
                $user->syncRoles([]);
                $user->delete();
            });
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

    private function saveAddress(User|SellerProfile|LogisticsProfile $addressable, User $user, array $data, string $label, bool $default = false): void
    {
        $addressable->addresses()->create([
            'label' => $label,
            'country_code' => $data['country_code'] ?? 'PH',
            'country_name' => $data['country_name'] ?? 'Philippines',
            'recipient_name' => $user->name,
            'phone' => $user->phone,
            'region_code' => $data['region_code'] ?? null,
            'province_code' => $data['province_code'] ?? null,
            'city_code' => $data['city_code'] ?? null,
            'barangay_code' => $data['barangay_code'] ?? null,
            'region_name' => $data['region_name'],
            'province_name' => $data['province_name'] ?? null,
            'city_name' => $data['city_name'],
            'barangay_name' => $data['barangay_name'] ?? null,
            'street_line' => $data['street_line'],
            'postal_code' => $data['postal_code'],
            'is_default' => $default,
        ]);
    }
}
