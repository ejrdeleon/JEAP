<?php

namespace App\Http\Controllers\Shipping;

use App\Http\Controllers\Controller;
use App\Models\Parcel;
use Illuminate\View\View;

class PageController extends Controller
{
    public function home(): View
    {
        return view('shipping.stub', ['figma' => '01_Home 1', 'title' => 'Shipping']);
    }

    public function track(): View
    {
        return view('shipping.stub', ['figma' => '02_Track_Shipment 1', 'title' => 'Track Shipment']);
    }

    public function ship(): View
    {
        return view('shipping.stub', ['figma' => '03_Ship_Now 1', 'title' => 'Ship Now']);
    }

    public function shipments(): View
    {
        return view('shipping.stub', ['figma' => '04_My_Shipments 1', 'title' => 'My Shipments']);
    }

    public function details(Parcel $parcel): View
    {
        $user = auth()->user();
        abort_unless(
            $user && ($user->hasAnyRole(['admin', 'logistics', 'courier', 'seller']) || $parcel->order?->buyer_id === $user->id),
            403
        );

        return view('shipping.stub', ['figma' => '05_Shipment_Details 1', 'title' => 'Shipment '.$parcel->tracking_number]);
    }

    public function services(): View
    {
        return view('shipping.stub', ['figma' => '06_Services 1', 'title' => 'Services']);
    }

    public function pricing(): View
    {
        return view('shipping.stub', ['figma' => '07_Pricing_Calculator 1', 'title' => 'Pricing Calculator']);
    }

    public function account(): View
    {
        return view('shipping.stub', ['figma' => '08_My_Account_Profile 1', 'title' => 'Shipping Account']);
    }
}
