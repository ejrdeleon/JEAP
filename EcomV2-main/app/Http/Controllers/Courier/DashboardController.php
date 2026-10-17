<?php

namespace App\Http\Controllers\Courier;

use App\Http\Controllers\Controller;
use App\Models\DeliveryAssignment;
use App\Models\PickupAssignment;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Illuminate\View\View;

class DashboardController extends Controller
{
    public function index(Request $request): View
    {
        $rider = $request->user()->courierProfile()->with('area')->firstOrFail();

        return view('courier.dashboard', [
            'figma' => '11_Driver_Courier_Dashboard 1',
            'rider' => $rider,
            'pickupAssignments' => PickupAssignment::query()->where('courier_id', $request->user()->id)
                ->whereIn('status', ['pending', 'accepted', 'picked_up'])
                ->with(['parcel.order.items', 'seller'])->latest('assigned_at')->get(),
            'deliveryAssignments' => DeliveryAssignment::query()->where('courier_id', $request->user()->id)
                ->whereIn('status', ['pending', 'accepted', 'out_for_delivery', 'delivered', 'failed'])
                ->with(['parcel.order.items', 'parcel.order.buyer'])->latest('assigned_at')->get(),
            'completedDeliveryCount' => DeliveryAssignment::query()->where('courier_id', $request->user()->id)
                ->where('status', 'delivered')->whereDate('delivered_at', today())->count(),
        ]);
    }

    public function updateAvailability(Request $request): RedirectResponse
    {
        $data = $request->validate(['is_online' => ['required', 'boolean']]);
        $profile = $request->user()->courierProfile()->firstOrFail();
        abort_unless($request->user()->isApproved(), 403);
        if ($data['is_online'] && $profile->license_expires_at?->lt(today())) {
            return back()->withErrors(['is_online' => 'Your driving license has expired. Contact your logistics company before going online.']);
        }
        $profile->update(['is_online' => $data['is_online']]);

        return back()->with('status', $profile->is_online ? 'You are online and can receive assignments.' : 'You are offline.');
    }

    public function updateProfile(Request $request): RedirectResponse
    {
        $profile = $request->user()->courierProfile()->firstOrFail();
        $data = $request->validate([
            'phone' => ['required', 'string', 'regex:/^(09\d{9}|\+639\d{9})$/'],
            'vehicle_type' => ['required', Rule::in(['motorcycle', 'car', 'van', 'truck'])],
            'plate_number' => ['required', 'string', 'max:20', Rule::unique('courier_profiles', 'plate_number')->ignore($profile->id)],
            'license_number' => ['required', 'string', 'max:16', Rule::unique('courier_profiles', 'license_number')->ignore($profile->id)],
            'license_expires_at' => ['required', 'date', 'after:today'],
        ]);
        $phone = preg_replace('/\D/', '', $data['phone']);
        $request->user()->update(['phone' => str_starts_with($data['phone'], '+63') ? '+'.$phone : '+63'.substr($phone, 1)]);
        $profile->update(collect($data)->except('phone')->all());

        return back()->with('status', 'Rider profile updated.');
    }
}
