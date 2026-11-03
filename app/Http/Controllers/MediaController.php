<?php

namespace App\Http\Controllers;

use App\Models\Shipment;
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

    public function proofOfDelivery(Request $request, Shipment $shipment): StreamedResponse
    {
        $user = $request->user();
        abort_unless($user, 403);
        $shipment->loadMissing('order');
        abort_unless($shipment->order, 404);

        $allowed = $shipment->order->buyer_id === $user->id
            || $shipment->order->seller_id === $user->id
            || (int) $shipment->courier_id === (int) $user->id
            || $user->hasAnyRole(['logistics', 'admin', 'super-admin']);
        abort_unless($allowed, 403);
        abort_unless($shipment->proof_of_delivery, 404);

        $path = $shipment->proof_of_delivery;
        $disk = Storage::disk('local')->exists($path)
            ? 'local'
            : (Storage::disk('public')->exists($path) ? 'public' : null);
        abort_unless($disk, 404);

        $mime = Storage::disk($disk)->mimeType($path) ?: 'image/jpeg';

        return Storage::disk($disk)->response($path, null, [
            'Content-Type' => $mime,
            'Cache-Control' => 'private, no-store',
            'X-Content-Type-Options' => 'nosniff',
        ]);
    }
}
