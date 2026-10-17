<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AddressController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $addresses = $request->user()->addresses()->latest()->get();

        return response()->json(['addresses' => $addresses]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'label' => ['required', 'string', 'max:80'],
            'recipient_name' => ['required', 'string', 'max:160'],
            'phone' => ['required', 'string', 'max:32'],
            'country_code' => ['nullable', 'string', 'size:2', 'alpha'],
            'country_name' => ['nullable', 'string', 'max:100'],
            'province_name' => ['required', 'string', 'max:100'],
            'city_name' => ['required', 'string', 'max:100'],
            'barangay_name' => ['required', 'string', 'max:100'],
            'region_name' => ['nullable', 'string', 'max:100'],
            'region_code' => ['nullable', 'string', 'regex:/^\d{1,16}$/'],
            'province_code' => ['nullable', 'string', 'regex:/^\d{1,16}$/'],
            'city_code' => ['nullable', 'string', 'regex:/^\d{1,16}$/'],
            'barangay_code' => ['nullable', 'string', 'regex:/^\d{1,16}$/'],
            'street_line' => ['required', 'string', 'max:255'],
            'postal_code' => ['required', 'string', 'max:10'],
            'is_default' => ['boolean'],
            'latitude' => ['nullable', 'required_with:longitude', 'numeric', 'between:-90,90'],
            'longitude' => ['nullable', 'required_with:latitude', 'numeric', 'between:-180,180'],
        ]);

        if (! empty($data['is_default'])) {
            $request->user()->addresses()->update(['is_default' => false]);
        }

        $address = $request->user()->addresses()->create($data);

        return response()->json(['address' => $address], 201);
    }

    public function destroy(Request $request, int $id): JsonResponse
    {
        $request->user()->addresses()->findOrFail($id)->delete();

        return response()->json(['message' => 'Address deleted.']);
    }
}
