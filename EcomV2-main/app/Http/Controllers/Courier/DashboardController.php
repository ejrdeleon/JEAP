<?php

namespace App\Http\Controllers\Courier;

use App\Http\Controllers\Controller;
use Illuminate\View\View;

class DashboardController extends Controller
{
    public function index(): View
    {
        return view('courier.dashboard', ['figma' => '11_Driver_Courier_Dashboard 1']);
    }
}
