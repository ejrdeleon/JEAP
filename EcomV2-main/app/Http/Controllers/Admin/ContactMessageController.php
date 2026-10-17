<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\ContactMessage;
use Illuminate\View\View;

class ContactMessageController extends Controller
{
    public function index(): View
    {
        return view('admin.contact-messages', [
            'messages' => ContactMessage::query()->latest()->paginate(20),
        ]);
    }
}
