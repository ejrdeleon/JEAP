<?php

namespace App\Http\Controllers\Buyer;

use App\Http\Controllers\Controller;
use App\Models\Address;
use App\Models\Order;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;

class DashboardController extends Controller
{
    public function home(): View
    {
        return view('buyer.home', ['figma' => '01_Buyer_Home 1']);
    }

    public function addresses(): View
    {
        return view('buyer.addresses', [
            'addresses' => request()->user()->addresses()->latest()->get(),
            'mapsKey' => config('services.google.maps_browser_key'),
        ]);
    }

    public function storeAddress(Request $request): RedirectResponse
    {
        $data = $request->validate($this->addressRules());
        $this->saveAddress($request, $data);

        return back()->with('toast', 'Delivery address saved.');
    }

    public function updateAddress(Request $request, int $address): RedirectResponse
    {
        $address = $request->user()->addresses()->findOrFail($address);
        $data = $request->validate($this->addressRules());
        $this->saveAddress($request, $data, $address);

        return back()->with('toast', 'Delivery address updated.');
    }

    public function deleteAddress(Request $request, int $address): RedirectResponse
    {
        $request->user()->addresses()->findOrFail($address)->delete();

        return back()->with('toast', 'Delivery address removed.');
    }

    public function search(): View
    {
        return view('buyer.stub', ['figma' => '03_Search_Filters 1', 'title' => 'Search & Filters']);
    }

    public function cart(): View
    {
        return view('buyer.stub', ['figma' => '04_MultiSeller_Cart 1', 'title' => 'Multi-seller Cart']);
    }

    public function checkout(): View
    {
        return view('buyer.stub', ['figma' => '05_Checkout_Payment 1', 'title' => 'Checkout Payment']);
    }

    public function track(Order $order): View
    {
        abort_unless($order->buyer_id === auth()->id() || auth()->user()?->hasRole('admin'), 403);

        return view('buyer.track', ['figma' => '06_Order_Tracking_Chat 1', 'order' => $order]);
    }

    private function addressRules(): array
    {
        return [
            'label' => ['nullable', 'string', 'max:64'],
            'recipient_name' => ['required', 'string', 'max:255'],
            'phone' => ['required', 'string', 'max:32'],
            'country_code' => ['nullable', 'string', 'size:2', 'alpha'],
            'country_name' => ['nullable', 'string', 'max:255'],
            'street_line' => ['required', 'string', 'max:255'],
            'city_name' => ['required', 'string', 'max:255'],
            'region_code' => ['nullable', 'string', 'regex:/^\d{1,16}$/'],
            'province_code' => ['nullable', 'string', 'regex:/^\d{1,16}$/'],
            'city_code' => ['nullable', 'string', 'regex:/^\d{1,16}$/'],
            'barangay_code' => ['nullable', 'string', 'regex:/^\d{1,16}$/'],
            'province_name' => ['nullable', 'string', 'max:255'],
            'region_name' => ['nullable', 'string', 'max:255'],
            'barangay_name' => ['nullable', 'string', 'max:255'],
            'postal_code' => ['nullable', 'string', 'max:16'],
            'latitude' => ['nullable', 'required_with:longitude', 'numeric', 'between:-90,90'],
            'longitude' => ['nullable', 'required_with:latitude', 'numeric', 'between:-180,180'],
            'is_default' => ['sometimes', 'boolean'],
        ];
    }

    private function saveAddress(Request $request, array $data, ?Address $address = null): void
    {
        DB::transaction(function () use ($request, $data, $address): void {
            $makeDefault = (bool) ($data['is_default'] ?? false)
                || (! $address && ! $request->user()->addresses()->exists());

            if ($makeDefault) {
                $request->user()->addresses()->update(['is_default' => false]);
            }

            $data['is_default'] = $makeDefault;

            if ($address) {
                $address->update($data);
            } else {
                $request->user()->addresses()->create($data);
            }
        });
    }
}
