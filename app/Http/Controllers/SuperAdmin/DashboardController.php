<?php

namespace App\Http\Controllers\SuperAdmin;

use App\Commerce\CommissionService;
use App\Commerce\InventoryPolicy;
use App\Enums\UserStatus;
use App\Http\Controllers\Controller;
use App\Http\Requests\UpdateAccountAccessRequest;
use App\Models\Announcement;
use App\Models\PlatformPolicy;
use App\Models\User;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;

class DashboardController extends Controller
{
    public function index(): View
    {
        return view('super-admin.dashboard', [
            'adminCount' => User::query()->role('admin')->count(),
            'activeAdmins' => User::query()->role('admin')->where('status', UserStatus::Active)->count(),
            'policyCount' => PlatformPolicy::query()->count(),
            'publishedAnnouncements' => Announcement::query()->where('is_published', true)->count(),
            'recentAdmins' => User::query()->role('admin')->latest()->limit(5)->get(),
        ]);
    }

    public function admins(): View
    {
        return view('super-admin.admins', [
            'admins' => User::query()->role('admin')->with(['roles', 'statusChangedBy'])->latest()->paginate(15),
        ]);
    }

    public function storeAdmin(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'first_name' => ['required', 'string', 'max:255'],
            'last_name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', 'unique:users,email'],
            'phone' => ['nullable', 'string', 'max:32'],
            'password' => ['required', 'string', 'min:12', 'confirmed'],
        ]);

        DB::transaction(function () use ($data): void {
            $admin = User::query()->create([
                'first_name' => $data['first_name'],
                'last_name' => $data['last_name'],
                'email' => $data['email'],
                'phone' => $data['phone'] ?? null,
                'password' => $data['password'],
                'password_set_at' => now(),
                'email_verified_at' => now(),
            ]);
            $admin->forceFill(['status' => UserStatus::Active])->save();
            $admin->syncRoles(['admin']);
        });

        return back()->with('status', 'Administrator account created.');
    }

    public function updateAdminStatus(UpdateAccountAccessRequest $request, User $user): RedirectResponse
    {
        abort_unless($user->hasRole('admin'), 404);
        abort_if($user->id === $request->user()->id || $user->hasRole('super-admin'), 403);

        $user->applyAccessStatus($request->accessStatus(), $request->accessReason(), $request->user());

        return back()->with('status', 'Administrator status updated.');
    }

    public function settings(): View
    {
        return view('super-admin.settings', [
            'policies' => PlatformPolicy::query()->orderBy('title')->paginate(15),
            'commissionRate' => CommissionService::rate(),
            'shippingFee' => InventoryPolicy::shippingFee(),
            'minSellableStock' => InventoryPolicy::minSellableStock(),
            'maxQtyPerProduct' => InventoryPolicy::maxQtyPerProduct(),
        ]);
    }

    public function updateCommerceRules(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'shipping_fee' => ['required', 'numeric', 'min:0', 'max:9999'],
            'min_sellable_stock' => ['required', 'integer', 'min:1', 'max:1000'],
            'max_qty_per_product' => ['required', 'integer', 'min:1', 'max:100'],
        ]);
        InventoryPolicy::setShippingFee((float) $data['shipping_fee']);
        InventoryPolicy::setMinSellableStock((int) $data['min_sellable_stock']);
        InventoryPolicy::setMaxQtyPerProduct((int) $data['max_qty_per_product']);

        return back()->with('status', 'Shipping fee, sellable stock, and cart cap were saved. Existing orders keep the shipping they already paid.');
    }

    public function storePolicy(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'key' => ['required', 'alpha_dash', 'max:255', 'unique:platform_policies,key'],
            'title' => ['required', 'string', 'max:255'],
            'body' => ['nullable', 'string', 'max:20000'],
        ]);

        PlatformPolicy::query()->create($data);

        return back()->with('status', 'Platform policy created.');
    }

    public function updatePolicy(Request $request, PlatformPolicy $policy): RedirectResponse
    {
        $data = $request->validate([
            'title' => ['required', 'string', 'max:255'],
            'body' => ['nullable', 'string', 'max:20000'],
        ]);

        $policy->update($data);

        return back()->with('status', 'Platform policy updated.');
    }
}
