<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\StreamedResponse;

class MediaController extends Controller
{
    public function avatar(Request $request, User $user): StreamedResponse
    {
        abort_unless($user->avatar_path && ! str_starts_with((string) $user->avatar_path, 'http'), 404);
        abort_unless(Storage::disk('public')->exists($user->avatar_path), 404);

        $mime = Storage::disk('public')->mimeType($user->avatar_path) ?: 'image/jpeg';

        return Storage::disk('public')->response($user->avatar_path, null, [
            'Content-Type' => $mime,
            'Cache-Control' => 'public, max-age=86400',
        ]);
    }
}
