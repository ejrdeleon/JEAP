<?php

namespace App\Http\Controllers\Buyer;

use App\Http\Controllers\Controller;
use App\Models\Product;
use App\Models\User;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class WishlistController extends Controller
{
    public function index(Request $request): View
    {
        return view('buyer.wishlist', [
            'products' => $request->user()->wishlistProducts()
                ->where('status', 'active')
                ->with(['images', 'variants' => fn ($query) => $query->where('is_active', true)])
                ->latest('buyer_wishlists.created_at')
                ->paginate(12),
            'followedSellers' => $request->user()->followedSellers()->orderBy('users.first_name')->get(),
        ]);
    }

    public function saveProduct(Request $request, Product $product): RedirectResponse
    {
        abort_unless($product->status === 'active' && $product->variants()->where('is_active', true)->exists(), 404);
        $request->user()->wishlistProducts()->syncWithoutDetaching([$product->id]);

        return back()->with('toast', 'Product saved to your wishlist.');
    }

    public function removeProduct(Request $request, Product $product): RedirectResponse
    {
        $request->user()->wishlistProducts()->detach($product->id);

        return back()->with('toast', 'Product removed from your wishlist.');
    }

    public function followSeller(Request $request, User $seller): RedirectResponse
    {
        abort_unless($seller->hasRole('seller') && $seller->status->value === 'active', 404);
        $request->user()->followedSellers()->syncWithoutDetaching([$seller->id]);

        return back()->with('toast', 'You are now following '.$seller->name.'.');
    }

    public function unfollowSeller(Request $request, User $seller): RedirectResponse
    {
        $request->user()->followedSellers()->detach($seller->id);

        return back()->with('toast', 'You unfollowed '.$seller->name.'.');
    }
}
