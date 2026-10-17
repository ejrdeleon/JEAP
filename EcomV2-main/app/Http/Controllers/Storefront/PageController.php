<?php

namespace App\Http\Controllers\Storefront;

use App\Commerce\CommissionService;
use App\Enums\OrderStatus;
use App\Http\Controllers\Controller;
use App\Models\Cart;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\OrderStatusHistory;
use App\Models\Payment;
use App\Models\ProductVariant;
use App\Payments\PaymentGateway;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;
use Illuminate\View\View;

class PageController extends Controller
{
    public function about(): View
    {
        return view('storefront.about');
    }

    public function contact(): View
    {
        return view('storefront.contact');
    }

    public function checkout(): View
    {
        $sessionId = session()->getId();
        $cart = Cart::query()
            ->when(auth()->check(), fn ($q) => $q->where('user_id', auth()->id()), fn ($q) => $q->where('session_id', $sessionId))
            ->with(['items.variant.product.images'])
            ->first();

        $addresses = auth()->user()->addresses()->latest()->get();

        return view('storefront.checkout', [
            'cart' => $cart,
            'addresses' => $addresses,
            'mapsKey' => config('services.google.maps_browser_key'),
        ]);
    }

    public function place(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'address_id' => ['nullable', 'integer'],
            'first_name' => [Rule::requiredIf(! $request->filled('address_id')), 'nullable', 'string', 'max:80'],
            'last_name' => [Rule::requiredIf(! $request->filled('address_id')), 'nullable', 'string', 'max:80'],
            'street' => [Rule::requiredIf(! $request->filled('address_id')), 'nullable', 'string', 'max:255'],
            'city' => [Rule::requiredIf(! $request->filled('address_id')), 'nullable', 'string', 'max:120'],
            'region_name' => ['nullable', 'string', 'max:120'],
            'barangay' => ['nullable', 'string', 'max:120'],
            'region_code' => ['nullable', 'string', 'regex:/^\d{1,16}$/'],
            'province_code' => ['nullable', 'string', 'regex:/^\d{1,16}$/'],
            'city_code' => ['nullable', 'string', 'regex:/^\d{1,16}$/'],
            'barangay_code' => ['nullable', 'string', 'regex:/^\d{1,16}$/'],
            'province' => ['nullable', 'string', 'max:120'],
            'country' => ['nullable', 'string', 'max:120'],
            'zip' => ['nullable', 'string', 'max:16'],
            'street2' => ['nullable', 'string', 'max:255'],
            'phone' => [Rule::requiredIf(! $request->filled('address_id')), 'nullable', 'string', 'max:32'],
            'country' => ['nullable', 'string', 'max:255'],
            'country_code' => ['nullable', 'string', 'size:2', 'alpha'],
            'email' => ['nullable', 'email', 'max:255'],
            'notes' => ['nullable', 'string', 'max:500'],
            'latitude' => ['nullable', 'required_with:longitude', 'numeric', 'between:-90,90'],
            'longitude' => ['nullable', 'required_with:latitude', 'numeric', 'between:-180,180'],
            'gateway' => ['required', 'in:cod'],
        ]);

        $buyer = $request->user();
        $orders = DB::transaction(function () use ($buyer, $data) {
            $cart = Cart::query()->where('user_id', $buyer->id)->lockForUpdate()->first();
            $items = $cart?->items()->lockForUpdate()->get() ?? collect();

            if ($items->isEmpty()) {
                throw ValidationException::withMessages([
                    'cart' => 'Your cart is empty.',
                ]);
            }

            if (! empty($data['address_id'])) {
                $savedAddress = $buyer->addresses()->lockForUpdate()->find($data['address_id']);
                if (! $savedAddress) {
                    throw ValidationException::withMessages([
                        'address_id' => 'Select one of your saved delivery addresses.',
                    ]);
                }
            } else {
                $savedAddress = $buyer->addresses()->create([
                    'label' => 'Checkout',
                    'recipient_name' => trim($data['first_name'].' '.$data['last_name']),
                    'phone' => $data['phone'],
                    'country_code' => strtoupper($data['country_code'] ?? 'PH'),
                    'country_name' => $data['country'] ?? 'Philippines',
                    'street_line' => trim($data['street'].(empty($data['street2']) ? '' : ', '.$data['street2'])),
                    'region_code' => $data['region_code'] ?? null,
                    'province_code' => $data['province_code'] ?? null,
                    'city_code' => $data['city_code'] ?? null,
                    'barangay_code' => $data['barangay_code'] ?? null,
                    'region_name' => $data['region_name'] ?? null,
                    'city_name' => $data['city'],
                    'province_name' => $data['province'] ?? null,
                    'barangay_name' => $data['barangay'] ?? null,
                    'postal_code' => $data['zip'] ?? null,
                    'latitude' => $data['latitude'] ?? null,
                    'longitude' => $data['longitude'] ?? null,
                    'is_default' => ! $buyer->addresses()->exists(),
                ]);
            }

            $address = [
                'recipient_name' => $savedAddress->recipient_name,
                'phone' => $savedAddress->phone,
                'country_code' => $savedAddress->country_code,
                'country_name' => $savedAddress->country_name,
                'email' => $data['email'] ?? $buyer->email,
                'street_line' => $savedAddress->street_line,
                'region_code' => $savedAddress->region_code,
                'province_code' => $savedAddress->province_code,
                'city_code' => $savedAddress->city_code,
                'barangay_code' => $savedAddress->barangay_code,
                'region_name' => $savedAddress->region_name,
                'barangay_name' => $savedAddress->barangay_name,
                'city_name' => $savedAddress->city_name,
                'province_name' => $savedAddress->province_name,
                'region_name' => $savedAddress->region_name,
                'postal_code' => $savedAddress->postal_code,
                'latitude' => $savedAddress->latitude,
                'longitude' => $savedAddress->longitude,
            ];

            $groupId = (string) Str::uuid();
            $orders = [];

            foreach ($items->groupBy('seller_id') as $sellerId => $sellerItems) {
                $lines = [];
                $subtotal = 0;

                foreach ($sellerItems as $item) {
                    $variant = ProductVariant::query()->whereKey($item->product_variant_id)
                        ->lockForUpdate()->with('product')->first();
                    if (! $variant || ! $variant->is_active || $variant->product?->status !== 'active' || $variant->product?->seller?->sellerProfile?->vacation_mode) {
                        throw ValidationException::withMessages([
                            'cart' => 'A product in your cart is no longer available. Remove it and try again.',
                        ]);
                    }
                    if ($variant->stock < $item->quantity) {
                        throw ValidationException::withMessages([
                            'cart' => "There is not enough stock for {$variant->product->name}.",
                        ]);
                    }

                    $variant->decrement('stock', $item->quantity);
                    $lineTotal = (float) $variant->price * $item->quantity;
                    $subtotal += $lineTotal;
                    $lines[] = [$item, $variant, $lineTotal];
                }

                $order = Order::create([
                    'checkout_group_id' => $groupId,
                    'order_number' => 'JEAP-'.strtoupper(Str::random(8)),
                    'buyer_id' => $buyer->id,
                    'seller_id' => $sellerId,
                    'status' => OrderStatus::Placed,
                    'subtotal' => $subtotal,
                    'shipping_fee' => 0,
                    'discount' => 0,
                    'total' => $subtotal,
                    'shipping_address_id' => $savedAddress->id,
                    'shipping_address_snapshot' => $address,
                    'notes' => $data['notes'] ?? null,
                    'placed_at' => now(),
                ]);

                app(CommissionService::class)->record($order);

                foreach ($lines as [$item, $variant, $lineTotal]) {
                    OrderItem::create([
                        'order_id' => $order->id,
                        'product_id' => $variant->product_id,
                        'product_variant_id' => $variant->id,
                        'name' => $variant->product->name,
                        'sku' => $variant->sku,
                        'quantity' => $item->quantity,
                        'unit_price' => $variant->price,
                        'subtotal' => $lineTotal,
                    ]);
                }

                OrderStatusHistory::create([
                    'order_id' => $order->id,
                    'to_status' => OrderStatus::Placed->value,
                    'created_at' => now(),
                ]);

                $intent = app(PaymentGateway::class)->initiate($order);
                Payment::create([
                    'checkout_group_id' => $groupId,
                    'order_id' => $order->id,
                    'gateway' => $intent->gateway,
                    'method' => 'cod',
                    'amount' => $order->total,
                    'status' => $intent->status,
                    'gateway_reference' => $intent->reference,
                    'payload' => $intent->payload,
                ]);

                $orders[] = $order;
            }

            $cart->items()->delete();

            return $orders;
        });

        return redirect()->route('buyer.home')->with('toast', 'Order placed successfully: '.implode(', ', array_map(fn ($order) => $order->order_number, $orders)));
    }

    public function profile(): View
    {
        return view('storefront.profile', ['user' => auth()->user()]);
    }

    public function updateProfile(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'first_name' => ['required', 'string', 'max:80'],
            'last_name' => ['required', 'string', 'max:80'],
            'email' => ['required', 'email', 'max:255', 'unique:users,email,'.$request->user()->id],
            'phone' => ['nullable', 'string', 'max:32'],
        ]);

        $request->user()->update($data);

        return back()->with('toast', 'Account info saved');
    }

    public function help(): View
    {
        return view('storefront.help');
    }
}
