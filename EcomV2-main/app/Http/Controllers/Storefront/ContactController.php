<?php

namespace App\Http\Controllers\Storefront;

use App\Http\Controllers\Controller;
use App\Models\ContactMessage;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Throwable;

class ContactController extends Controller
{
    public function store(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'full_name' => ['required', 'string', 'min:2', 'max:120'],
            'email' => ['required', 'email:rfc', 'max:255'],
            'category' => ['required', Rule::in(['order', 'delivery', 'account', 'general'])],
            'order_number' => ['nullable', 'string', 'max:80'],
            'message' => ['required', 'string', 'min:10', 'max:5000'],
            'website' => ['prohibited'],
        ]);

        unset($data['website']);

        try {
            ContactMessage::query()->create($data);
        } catch (Throwable $exception) {
            report($exception);

            return to_route('contact')
                ->withInput(collect($data)->except('message')->all())
                ->with('contact_error', 'We could not save your message right now. Please call JEAP support or try again shortly.');
        }

        return to_route('contact')->with('contact_sent', true);
    }
}
