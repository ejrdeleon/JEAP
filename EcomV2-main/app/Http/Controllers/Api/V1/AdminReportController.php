<?php

namespace App\Http\Controllers\Api\V1;

use App\Enums\UserStatus;
use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

class AdminReportController extends Controller
{
    public function index(): JsonResponse
    {
        $rangeStart = Carbon::now()->startOfMonth()->subMonths(5);
        $monthlySales = Order::query()
            ->where('created_at', '>=', $rangeStart)
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

        return response()->json([
            'total_orders' => Order::query()->count(),
            'gross_sales' => (float) Order::query()->whereNotIn('status', ['CANCELLED', 'RETURNED'])->sum('total'),
            'active_users' => User::query()->where('status', UserStatus::Active)
                ->whereDoesntHave('roles', fn ($query) => $query->whereIn('name', ['admin', 'super-admin']))->count(),
            'user_statuses' => User::query()->selectRaw('status, count(*) as total')->groupBy('status')->get(),
            'monthly_sales' => $months,
            'top_products' => DB::table('order_items')
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
