<?php

namespace App\Http\Controllers\Seller;

use App\Commerce\InventoryPolicy;
use App\Enums\OrderStatus;
use App\Enums\PaymentStatus;
use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\Order;
use App\Models\OrderStatusHistory;
use App\Models\Parcel;
use App\Models\PickupAssignment;
use App\Models\Product;
use App\Models\ProductVariant;
use App\Models\Voucher;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Illuminate\View\View;

class DashboardController extends Controller
{
    public function index(): View
    {
        $sellerId = auth()->id();

        return view('seller.dashboard', [
            'productCount' => Product::query()->where('seller_id', $sellerId)->where('status', 'active')->count(),
            'lowStockCount' => ProductVariant::query()->whereHas('product', fn ($q) => $q->where('seller_id', $sellerId)->where('status', 'active'))->where('is_active', true)->where('stock', '<', InventoryPolicy::minSellableStock())->count(),
            'openOrderCount' => Order::query()->where('seller_id', $sellerId)->whereNotIn('status', [OrderStatus::Completed->value, OrderStatus::Cancelled->value, OrderStatus::Returned->value])->count(),
            'recentOrders' => Order::query()->where('seller_id', $sellerId)->with(['items', 'commission'])->latest('placed_at')->take(6)->get(),
        ]);
    }

    public function catalog(): View
    {
        return view('seller.catalog', [
            'products' => Product::query()->where('seller_id', auth()->id())
                ->with(['category', 'images', 'variants'])
                ->latest()->paginate(12),
            'categories' => Category::query()->where('is_active', true)->orderBy('sort_order')->get(),
            'editingProduct' => null,
        ]);
    }

    public function storeProduct(Request $request): RedirectResponse
    {
        $data = $this->validatedProduct($request);
        $product = Product::query()->create([
            'seller_id' => $request->user()->id,
            'category_id' => $data['category_id'],
            'name' => $data['name'],
            'slug' => $this->uniqueSlug($data['name']),
            'description' => $data['description'] ?? null,
            'status' => $data['status'],
        ]);

        $variant = $product->variants()->create([
            'sku' => $this->uniqueSku(),
            'price' => $data['price'],
            'compare_at_price' => $data['compare_at_price'] ?? null,
            'stock' => $data['stock'],
            'is_active' => true,
        ]);

        $this->saveProductImage($request, $product, $variant);

        return redirect()->route('seller.catalog')->with('status', 'Product added to your catalog.');
    }

    public function editProduct(Product $product): View
    {
        $product = $this->ownedProduct($product);

        return view('seller.catalog', [
            'products' => Product::query()->where('seller_id', auth()->id())
                ->with(['category', 'images', 'variants'])->latest()->paginate(12),
            'categories' => Category::query()->where('is_active', true)->orderBy('sort_order')->get(),
            'editingProduct' => $product->load(['category', 'images', 'variants']),
        ]);
    }

    public function updateProduct(Request $request, Product $product): RedirectResponse
    {
        $product = $this->ownedProduct($product);
        $data = $this->validatedProduct($request);
        $product->update([
            'category_id' => $data['category_id'],
            'name' => $data['name'],
            'slug' => $product->name === $data['name'] ? $product->slug : $this->uniqueSlug($data['name'], $product->id),
            'description' => $data['description'] ?? null,
            'status' => $data['status'],
        ]);

        $variant = $product->variants()->orderBy('id')->first();
        if (! $variant) {
            $variant = $product->variants()->make(['sku' => $this->uniqueSku()]);
        }
        $variant->fill([
            'price' => $data['price'],
            'compare_at_price' => $data['compare_at_price'] ?? null,
            'stock' => $data['stock'],
            'is_active' => true,
        ])->save();

        $this->saveProductImage($request, $product, $variant);

        return redirect()->route('seller.catalog')->with('status', 'Product changes saved.');
    }

    public function archiveProduct(Product $product): RedirectResponse
    {
        $product = $this->ownedProduct($product);
        $product->update(['status' => 'inactive']);
        $product->variants()->update(['is_active' => false]);

        return redirect()->route('seller.catalog')->with('status', 'Product archived and removed from the storefront.');
    }

    public function orders(): View
    {
        return view('seller.orders', [
            'orders' => Order::query()->where('seller_id', auth()->id())
                ->with(['buyer', 'items', 'commission', 'parcel.pickupAssignment.courier', 'parcel.deliveryAssignment.courier'])->latest('placed_at')->paginate(15),
        ]);
    }

    public function updateOrderStatus(Request $request, Order $order): RedirectResponse
    {
        abort_unless($order->seller_id === $request->user()->id, 404);

        $transitions = [
            OrderStatus::Placed->value => [OrderStatus::Confirmed, OrderStatus::Cancelled],
            OrderStatus::Confirmed->value => [OrderStatus::Preparing, OrderStatus::Cancelled],
            OrderStatus::Preparing->value => [OrderStatus::ReadyForPickup],
        ];
        $data = $request->validate([
            'status' => ['required', Rule::in(array_map(fn (OrderStatus $status) => $status->value, [OrderStatus::Confirmed, OrderStatus::Preparing, OrderStatus::ReadyForPickup, OrderStatus::Cancelled]))],
        ]);
        $next = OrderStatus::from($data['status']);

        DB::transaction(function () use ($order, $next, $request, $transitions): void {
            $lockedOrder = Order::query()->whereKey($order->id)->lockForUpdate()->firstOrFail();
            $current = $lockedOrder->status;
            abort_unless(in_array($next, $transitions[$current->value] ?? [], true), 409);

            if ($next === OrderStatus::Cancelled) {
                foreach ($lockedOrder->items as $item) {
                    ProductVariant::query()->whereKey($item->product_variant_id)->increment('stock', $item->quantity);
                }
                $lockedOrder->payments()->where('status', PaymentStatus::Pending->value)->update(['status' => PaymentStatus::Cancelled->value]);
                $lockedOrder->commission()->update(['status' => 'void']);
            }

            $lockedOrder->update(['status' => $next]);
            OrderStatusHistory::query()->create([
                'order_id' => $lockedOrder->id,
                'from_status' => $current,
                'to_status' => $next,
                'actor_id' => $request->user()->id,
                'notes' => $next === OrderStatus::ReadyForPickup ? 'Seller marked the order ready for pickup.' : null,
                'created_at' => now(),
            ]);

            if ($next === OrderStatus::ReadyForPickup) {
                $parcel = Parcel::query()->firstOrCreate(
                    ['order_id' => $lockedOrder->id],
                    [
                        'tracking_number' => 'JEP'.strtoupper(Str::random(10)),
                        'status' => OrderStatus::ReadyForPickup,
                    ]
                );

                $parcel->update(['status' => OrderStatus::ReadyForPickup]);
                PickupAssignment::query()->firstOrCreate(
                    ['parcel_id' => $parcel->id],
                    ['seller_id' => $lockedOrder->seller_id, 'status' => 'pending']
                );
            }
        });

        return back()->with('status', 'Order status updated to '.str($next->value)->replace('_', ' ')->lower().'.');
    }

    public function promos(): View
    {
        return view('seller.promos', [
            'vouchers' => Voucher::query()->where('seller_id', auth()->id())->latest()->get(),
        ]);
    }

    public function storePromo(Request $request): RedirectResponse
    {
        $request->merge(['code' => strtoupper(trim((string) $request->input('code')))]);
        $data = $request->validate([
            'code' => ['required', 'string', 'min:3', 'max:20', 'regex:/^[A-Z0-9_-]+$/', 'unique:vouchers,code'],
            'type' => ['required', Rule::in(['percent', 'fixed'])],
            'value' => ['required', 'numeric', 'min:1', $request->input('type') === 'percent' ? 'max:80' : 'max:999999'],
            'min_order' => ['nullable', 'numeric', 'min:0'],
            'max_discount' => ['nullable', 'numeric', 'min:0'],
            'usage_limit' => ['nullable', 'integer', 'min:1', 'max:100000'],
            'starts_at' => ['nullable', 'date'],
            'expires_at' => ['nullable', 'date', 'after:starts_at'],
        ]);
        $data['code'] = strtoupper($data['code']);
        $data['seller_id'] = auth()->id();
        $data['is_active'] = true;
        Voucher::query()->create($data);

        return back()->with('status', 'Shop voucher '.$data['code'].' is ready.');
    }

    public function togglePromo(Voucher $voucher): RedirectResponse
    {
        abort_unless($voucher->seller_id === auth()->id(), 403);
        $voucher->update(['is_active' => ! $voucher->is_active]);

        return back()->with('status', $voucher->is_active ? 'Voucher is on.' : 'Voucher is paused.');
    }

    public function destroyPromo(Voucher $voucher): RedirectResponse
    {
        abort_unless($voucher->seller_id === auth()->id(), 403);
        $voucher->delete();

        return back()->with('status', 'Voucher removed.');
    }

    public function shipments(): View
    {
        return view('seller.shipments', [
            'orders' => Order::query()->where('seller_id', auth()->id())
                ->whereHas('parcel')
                ->with(['parcel.pickupAssignment.courier', 'parcel.deliveryAssignment.courier'])
                ->latest('placed_at')->paginate(15),
        ]);
    }

    private function validatedProduct(Request $request): array
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:180'],
            'category_id' => ['required', 'integer', Rule::exists('categories', 'id')->where('is_active', true)],
            'description' => ['nullable', 'string', 'max:10000'],
            'price' => ['required', 'numeric', 'min:0.01', 'max:999999999'],
            'compare_at_price' => ['nullable', 'numeric', 'gt:price', 'max:999999999'],
            'stock' => ['required', 'integer', 'min:0', 'max:1000000'],
            'status' => ['required', Rule::in(['active', 'draft'])],
            'image' => ['nullable', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
        ]);

        if ($data['status'] === 'active' && $data['stock'] < InventoryPolicy::minSellableStock()) {
            throw \Illuminate\Validation\ValidationException::withMessages([
                'stock' => 'Active listings need at least '.InventoryPolicy::minSellableStock().' units in stock before they can be sold.',
            ]);
        }

        return $data;
    }

    private function ownedProduct(Product $product): Product
    {
        abort_unless($product->seller_id === auth()->id(), 404);

        return $product;
    }

    private function uniqueSlug(string $name, ?int $ignoreId = null): string
    {
        $base = Str::slug($name) ?: 'product';
        $slug = $base;
        $suffix = 2;

        while (Product::query()->where('slug', $slug)->when($ignoreId, fn ($q) => $q->where('id', '<>', $ignoreId))->exists()) {
            $slug = $base.'-'.$suffix++;
        }

        return $slug;
    }

    private function uniqueSku(): string
    {
        do {
            $sku = 'JEP-'.Str::upper(Str::random(10));
        } while (ProductVariant::query()->where('sku', $sku)->exists());

        return $sku;
    }

    private function saveProductImage(Request $request, Product $product, ProductVariant $variant): void
    {
        if (! $request->hasFile('image')) {
            return;
        }

        $oldImage = $product->images()->first();
        $path = $request->file('image')->store('products', 'public');
        $product->images()->updateOrCreate(
            ['sort_order' => 0],
            ['variant_id' => $variant->id, 'path' => 'storage/'.$path, 'alt' => $product->name]
        );

        if ($oldImage && $oldImage->path !== 'storage/'.$path && Str::startsWith($oldImage->path, 'storage/products/')) {
            Storage::disk('public')->delete(Str::after($oldImage->path, 'storage/'));
        }
    }
}
