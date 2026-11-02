<?php

namespace App\Http\Controllers\Seller;

use App\Http\Controllers\Controller;
use App\Models\SellerProfile;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\View\View;

class StoreProfileController extends Controller
{
    public function edit(Request $request): View
    {
        $profile = $request->user()->sellerProfile()->firstOrFail();

        return view('seller.store-profile', compact('profile'));
    }

    public function update(Request $request): RedirectResponse
    {
        $profile = $request->user()->sellerProfile()->firstOrFail();
        $data = $request->validate([
            'business_name' => ['required', 'string', 'min:3', 'max:30', function (string $attribute, mixed $value, \Closure $fail) use ($profile): void {
                $normalized = mb_strtolower(trim((string) $value));
                $exists = SellerProfile::query()->where('user_id', '<>', $profile->user_id)
                    ->whereRaw('LOWER(TRIM(business_name)) = ?', [$normalized])->exists();
                if ($exists) {
                    $fail('This store name is already in use.');
                }
            }],
            'description' => ['nullable', 'string', 'max:500'],
            'contact_phone' => ['required', 'string', 'regex:/^(09\d{9}|\+639\d{9})$/'],
            'logo' => ['nullable', 'image', 'mimes:jpg,jpeg,png', 'max:5120'],
            'banner' => ['nullable', 'image', 'mimes:jpg,jpeg,png', 'max:5120'],
            'vacation_mode' => ['sometimes', 'boolean'],
            'remove_logo' => ['sometimes', 'boolean'],
            'remove_banner' => ['sometimes', 'boolean'],
        ]);
        $data['business_name'] = trim($data['business_name']);
        $data['description'] = isset($data['description']) ? trim($data['description']) : null;
        $data['contact_phone'] = $this->normalizePhone($data['contact_phone']);
        $data['vacation_mode'] = (bool) ($data['vacation_mode'] ?? false);

        foreach (['logo', 'banner'] as $imageField) {
            $pathField = $imageField.'_path';
            if ($request->hasFile($imageField)) {
                $data[$pathField] = 'storage/'.$request->file($imageField)->store('stores/'.$profile->user_id, 'public');
                $this->deleteManagedImage($profile->{$pathField});
            } elseif (! empty($data['remove_'.$imageField])) {
                $this->deleteManagedImage($profile->{$pathField});
                $data[$pathField] = null;
            }
            unset($data[$imageField], $data['remove_'.$imageField]);
        }

        $profile->update($data);

        return back()->with('status', 'Store profile updated.');
    }

    private function normalizePhone(string $phone): string
    {
        $digits = preg_replace('/\D/', '', $phone);

        return str_starts_with($phone, '+63') ? '+'.$digits : '+63'.substr($digits, 1);
    }

    private function deleteManagedImage(?string $path): void
    {
        if ($path && str_starts_with($path, 'storage/stores/')) {
            Storage::disk('public')->delete(substr($path, strlen('storage/')));
        }
    }
}
