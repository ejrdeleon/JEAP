<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\ContactMessage;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class ContactMessageController extends Controller
{
    public function index(): View
    {
        return view('admin.contact-messages', [
            'messages' => ContactMessage::query()->latest()->paginate(20),
        ]);
    }

    public function reply(Request $request, ContactMessage $message): RedirectResponse
    {
        $data = $request->validate([
            'admin_reply' => ['required', 'string', 'min:4', 'max:5000'],
        ]);
        $message->update([
            'admin_reply' => $data['admin_reply'],
            'replied_at' => now(),
        ]);

        return back()->with('status', 'Reply saved. Email '.$message->email.' from your mail client if you also need to send it.');
    }
}
