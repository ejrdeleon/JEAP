<?php

namespace App\Http\Controllers\Admin;

use App\Commerce\CommissionService;
use App\Enums\UserStatus;
use App\Http\Controllers\Controller;
use App\Models\Announcement;
use App\Models\Commission;
use App\Models\Complaint;
use App\Models\Order;
use App\Models\User;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;

class DashboardController extends Controller
{
    public function index(): View
    {
        return view('admin.dashboard', [
            'pendingCount' => User::query()->where('status', UserStatus::PendingApproval)->count(),
            'activeUsers' => User::query()->where('status', UserStatus::Active)
                ->whereDoesntHave('roles', fn ($query) => $query->whereIn('name', ['admin', 'super-admin']))->count(),
            'ordersToday' => Order::query()->whereDate('created_at', today())->count(),
            'salesThisMonth' => Order::query()->whereMonth('created_at', now()->month)
                ->whereYear('created_at', now()->year)
                ->whereNotIn('status', ['CANCELLED', 'RETURNED'])
                ->sum('total'),
            'openDisputes' => Complaint::query()->whereIn('status', ['open', 'under_review'])->count(),
            'logisticsCommission' => Commission::query()->whereNotIn('status', ['void'])->sum('amount'),
            'commissionRate' => CommissionService::rate(),
            'recentOrders' => Order::query()->with(['buyer', 'seller', 'commission'])->latest()->limit(8)->get(),
        ]);
    }

    public function cms(): View
    {
        return view('admin.cms', [
            'announcements' => Announcement::query()->latest()->paginate(10),
        ]);
    }

    public function users(): View
    {
        $users = User::query()
            ->with('roles')
            ->whereDoesntHave('roles', fn ($query) => $query->whereIn('name', ['admin', 'super-admin']))
            ->whereIn('status', [UserStatus::Active, UserStatus::Suspended, UserStatus::Deactivated])
            ->when(request('status'), fn ($query, $status) => $query->where('status', $status))
            ->when(request('q'), function ($query, $search): void {
                $query->where(function ($query) use ($search): void {
                    $query->where('first_name', 'like', '%'.$search.'%')
                        ->orWhere('last_name', 'like', '%'.$search.'%')
                        ->orWhere('email', 'like', '%'.$search.'%');
                });
            })
            ->latest()
            ->paginate(15)
            ->withQueryString();

        return view('admin.users', [
            'users' => $users,
            'statuses' => UserStatus::cases(),
        ]);
    }

    public function disputes(): View
    {
        return view('admin.disputes', [
            'complaints' => Complaint::query()->with(['complainant', 'againstUser', 'order'])
                ->latest()->paginate(15),
        ]);
    }

    public function reports(): View
    {
        $rangeStart = Carbon::now()->startOfMonth()->subMonths(5);
        $monthlySales = Order::query()->where('created_at', '>=', $rangeStart)
            ->whereNotIn('status', ['CANCELLED', 'RETURNED'])
            ->get(['created_at', 'total'])
            ->groupBy(fn (Order $order) => $order->created_at->format('Y-m'))
            ->map(fn ($orders) => (float) $orders->sum('total'));
        $months = collect(range(5, 0))->map(function (int $offset) use ($monthlySales): array {
            $month = now()->startOfMonth()->subMonths($offset);

            return [
                'label' => $month->format('M Y'),
                'sales' => $monthlySales->get($month->format('Y-m'), 0),
            ];
        });

        return view('admin.reports', [
            'totalOrders' => Order::query()->count(),
            'grossSales' => Order::query()->whereNotIn('status', ['CANCELLED', 'RETURNED'])->sum('total'),
            'activeUsers' => User::query()->where('status', UserStatus::Active)
                ->whereDoesntHave('roles', fn ($query) => $query->whereIn('name', ['admin', 'super-admin']))->count(),
            'userStatuses' => User::query()->selectRaw('status, count(*) as total')->groupBy('status')->get(),
            'monthlySales' => $months,
            'logisticsCommission' => Commission::query()->whereNotIn('status', ['void'])->sum('amount'),
            'pendingCommission' => Commission::query()->where('status', 'pending')->sum('amount'),
            'commissionRate' => CommissionService::rate(),
            'topProducts' => DB::table('order_items')
                ->join('orders', 'orders.id', '=', 'order_items.order_id')
                ->whereNotIn('orders.status', ['CANCELLED', 'RETURNED'])
                ->select('order_items.name')
                ->selectRaw('SUM(order_items.quantity) as units_sold, SUM(order_items.subtotal) as revenue')
                ->groupBy('order_items.name')
                ->orderByDesc('units_sold')
                ->limit(8)
                ->get(),
        ]);
    }
}
