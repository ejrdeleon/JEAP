<?php

namespace App\Http\Controllers\Logistics;

use App\Http\Controllers\Controller;
use Illuminate\View\View;

class DashboardController extends Controller
{
    public function index(): View
    {
        return view('logistics.dashboard', ['figma' => '12_Warehouse_Management 1']);
    }
}
