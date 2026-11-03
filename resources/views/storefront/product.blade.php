@extends('layouts.storefront')

@section('title', $product->name)
@section('crumb')
    <a href="{{ route('products.index') }}">Shop</a>
    <span>/</span>
    <a href="{{ route('products.index', ['category' => $product->category?->slug]) }}">{{ $product->category?->name }}</a>
    <span>/</span>
    <span>{{ $product->name }}</span>
@endsection

@section('content')
@php
    $variant = $product->defaultVariant();
    $images = $product->images;
    $main = $product->primaryImage();
    $shipping = \App\Commerce\InventoryPolicy::shippingFee();
    $maxQty = $variant ? min(\App\Commerce\InventoryPolicy::maxQtyPerProduct(), $variant->stock) : 1;
    $canBuy = $variant?->isSellable();
    $price = (float) ($variant?->price ?? 0);
    $compare = (float) ($variant?->compare_at_price ?? 0);
    $onSale = $compare > $price && $price > 0;
    $savePct = $onSale ? (int) round((1 - ($price / $compare)) * 100) : 0;
    $storeName = $product->seller?->sellerProfile?->business_name ?? $product->seller?->name ?? 'JEAP';
    $isNew = $product->created_at?->gt(now()->subDays(30));
    $ratingCount = $product->reviews->count();
    $ratingAvg = $ratingCount ? round((float) $product->reviews->avg('rating'), 1) : null;
@endphp
<section class="s3-main pdp-page">
    <div class="pdp-hero">
        <div class="pdp-gallery" data-pdp-gallery>
            <div class="pdp-gallery-stage">
                @if($main)
                    <img src="{{ asset($main->path) }}" alt="{{ $product->name }}" data-pdp-stage>
                @else
                    <div class="pdp-gallery-empty">No photo yet</div>
                @endif
                @if($isNew)
                    <span class="pdp-badge pdp-badge--new">New</span>
                @endif
                @if($onSale)
                    <span class="pdp-badge pdp-badge--sale">−{{ $savePct }}%</span>
                @endif
            </div>
            @if($images->count() > 1)
                <div class="pdp-thumbs" role="list">
                    @foreach($images as $index => $image)
                        <button type="button" class="pdp-thumb {{ $index === 0 ? 'is-on' : '' }}" data-pdp-thumb="{{ asset($image->path) }}" aria-label="Photo {{ $index + 1 }}">
                            <img src="{{ asset($image->path) }}" alt="">
                        </button>
                    @endforeach
                </div>
            @endif
        </div>

        <div class="pdp-info">
            @if($product->category)
                <a class="pdp-kicker" href="{{ route('products.index', ['category' => $product->category->slug]) }}">{{ $product->category->name }}</a>
            @endif
            <h1>{{ $product->name }}</h1>
            <p class="pdp-rating">
                @if($ratingAvg)
                    ★ {{ number_format($ratingAvg, 1) }} · {{ $ratingCount }} {{ Str::plural('review', $ratingCount) }}
                @else
                    No customer reviews yet
                @endif
            </p>
            <div class="pdp-price-row">
                <strong>₱{{ number_format($price, 2) }}</strong>
                @if($onSale)
                    <span class="compare">₱{{ number_format($compare, 2) }}</span>
                    <span class="pdp-save-tag">Save ₱{{ number_format($compare - $price, 2) }}</span>
                @endif
            </div>
            @if($product->description)
                <p class="pdp-lead">{{ $product->description }}</p>
            @endif
            <ul class="pdp-perks">
                <li>Cash on Delivery</li>
                <li>₱{{ number_format($shipping, 0) }} flat shipping</li>
                <li>Ships with {{ config('jeap.courier_name') }}</li>
                <li>Up to {{ \App\Commerce\InventoryPolicy::maxQtyPerProduct() }} per order</li>
            </ul>
            @if($variant?->color || $variant?->size)
                <dl class="pdp-options">
                    @if($variant?->color)
                        <div><dt>Color</dt><dd>{{ $variant->color }}</dd></div>
                    @endif
                    @if($variant?->size)
                        <div><dt>Size</dt><dd>{{ $variant->size }}</dd></div>
                    @endif
                </dl>
            @endif
            <dl class="pdp-facts">
                @if($variant?->sku)
                    <div><dt>SKU</dt><dd>{{ $variant->sku }}</dd></div>
                @endif
                @if($product->category)
                    <div><dt>Category</dt><dd>{{ $product->category->name }}</dd></div>
                @endif
                <div>
                    <dt>Store</dt>
                    <dd>
                        @if($product->seller)
                            <a href="{{ route('stores.show', $product->seller) }}">{{ $storeName }}</a>
                        @else
                            JEAP
                        @endif
                    </dd>
                </div>
            </dl>
        </div>

        <aside class="pdp-buy">
            <div class="pdp-paycard">
                <small>Total</small>
                <div class="price" data-pdp-total>₱{{ number_format($price, 2) }}</div>
                <p class="in-stock" aria-live="polite">{{ $canBuy ? '● In stock' : 'Not available to sell yet' }}</p>
                <form method="post" action="{{ route('cart.add') }}" data-cart-add-form data-existing-quantity="{{ $cartQuantity }}" data-unit-price="{{ $price }}">
                    @csrf
                    @if($variant)
                        <input type="hidden" name="product_variant_id" value="{{ $variant->id }}">
                    @endif
                    <div class="s3-qty pdp-qty" data-quantity-control>
                        <button type="button" data-quantity-decrease aria-label="Decrease quantity" @disabled(! $canBuy)>−</button>
                        <input type="number" name="quantity" value="1" min="1" max="{{ $maxQty }}" data-quantity-input @disabled(! $canBuy)>
                        <button type="button" data-quantity-increase aria-label="Increase quantity" @disabled(! $canBuy)>+</button>
                    </div>
                    <button class="s3-add" type="submit" @disabled(! $canBuy)>Add To Cart</button>
                    @if(! $canBuy)
                        <p class="cart-stock is-unavailable">Sellers need at least {{ \App\Commerce\InventoryPolicy::minSellableStock() }} units in stock before this can be sold. Limit {{ \App\Commerce\InventoryPolicy::maxQtyPerProduct() }} per product in cart.</p>
                    @endif
                </form>
                @auth
                    @if(auth()->user()->hasRole('buyer'))
                        <div class="pdp-save-actions">
                            <form method="post" action="{{ route($isWishlisted ? 'buyer.wishlist.remove' : 'buyer.wishlist.save', $product) }}">
                                @csrf
                                @if($isWishlisted) @method('DELETE') @endif
                                <button type="submit">{{ $isWishlisted ? '♥ Saved to wishlist' : '♡ Save to wishlist' }}</button>
                            </form>
                            <form method="post" action="{{ route($isFollowingSeller ? 'buyer.sellers.unfollow' : 'buyer.sellers.follow', $product->seller) }}">
                                @csrf
                                @if($isFollowingSeller) @method('DELETE') @endif
                                <button type="submit">{{ $isFollowingSeller ? 'Following this store' : 'Follow this store' }}</button>
                            </form>
                        </div>
                    @endif
                @else
                    <a class="pdp-save-link" href="{{ route('login') }}">Log in to save this product</a>
                @endauth
                <p class="pdp-pay-note">Cash on Delivery · ₱{{ number_format($shipping, 0) }} shipping</p>
            </div>
            @if($product->seller)
                @auth
                    <form method="post" action="{{ route('chat.start') }}" class="pdp-chat-form">
                        @csrf
                        <input type="hidden" name="seller_id" value="{{ $product->seller->id }}">
                        <button class="pdp-chat-btn" type="submit">Chat with seller</button>
                    </form>
                @else
                    <a class="pdp-chat-btn" href="{{ route('login') }}">Log in to chat with seller</a>
                @endauth
            @endif
            <p class="pdp-ship">Ships from the Philippines · {{ config('jeap.courier_name') }}</p>
        </aside>
    </div>

    <div class="pdp-body">
        <section class="pdp-panel">
            <h2>About this product</h2>
            @if($product->description)
                <p>{{ $product->description }}</p>
            @else
                <p>{{ $product->name }} is sold on JEAP with Cash on Delivery and {{ config('jeap.courier_name') }} delivery.</p>
            @endif
            <ul class="pdp-spec">
                @if($variant?->color)<li><span>Color</span><strong>{{ $variant->color }}</strong></li>@endif
                @if($variant?->size)<li><span>Size</span><strong>{{ $variant->size }}</strong></li>@endif
                <li><span>Payment</span><strong>Cash on Delivery</strong></li>
                <li><span>Shipping</span><strong>₱{{ number_format($shipping, 0) }} · {{ config('jeap.courier_name') }}</strong></li>
            </ul>
        </section>
        <section class="pdp-panel">
            <h2>Sold by {{ $storeName }}</h2>
            <p>Ask the seller before you buy if you need more photos, size help, or a stock check. Orders ship from the Philippines with {{ config('jeap.courier_name') }}.</p>
            @if($product->seller)
                <a class="pdp-store-link" href="{{ route('stores.show', $product->seller) }}">Visit store</a>
            @endif
        </section>
    </div>

    <section class="pdp-panel pdp-reviews-panel" id="reviews">
        <h2>Customer reviews</h2>
        @if(session('status'))<p class="pdp-review-flash" role="status">{{ session('status') }}</p>@endif
        @if($ratingCount)
            <p class="pdp-rating">★ {{ number_format($ratingAvg, 1) }} / 5 · {{ $ratingCount }} {{ Str::plural('review', $ratingCount) }}</p>
        @else
            <p>No customer reviews yet. Buyers can rate this product after they confirm a Cash on Delivery order.</p>
        @endif
        @if($reviewOrder ?? null)
            <form method="post" action="{{ route('buyer.orders.review', $reviewOrder) }}" class="pdp-review-form">
                @csrf
                <input type="hidden" name="product_id" value="{{ $product->id }}">
                <p class="pdp-review-form-label">{{ ($existingReview ?? null) ? 'Update your review' : 'Leave a review' }}</p>
                <label>Rating
                    <select name="rating" required>
                        @for($star = 5; $star >= 1; $star--)
                            <option value="{{ $star }}" @selected((int) (($existingReview->rating ?? 5)) === $star)>{{ $star }} star{{ $star === 1 ? '' : 's' }}</option>
                        @endfor
                    </select>
                </label>
                <label>Comment <span>(optional)</span>
                    <textarea name="comment" maxlength="1000" rows="3" placeholder="What did you think of this product?">{{ old('comment', $existingReview->comment ?? '') }}</textarea>
                </label>
                <button type="submit">{{ ($existingReview ?? null) ? 'Update review' : 'Post review' }}</button>
            </form>
        @elseif(auth()->guest())
            <p class="pdp-review-hint"><a href="{{ route('login') }}">Log in</a> after you receive your order to leave a review.</p>
        @endif
        @if($ratingCount)
            <ul class="pdp-reviews">
                @foreach($product->reviews as $review)
                    <li>
                        <div class="pdp-review-head">
                            <strong>{{ str_repeat('★', $review->rating) }}{{ str_repeat('☆', 5 - $review->rating) }}</strong>
                            <span>{{ $review->buyer?->name ?? 'JEAP buyer' }}</span>
                            @if($review->created_at)<time datetime="{{ $review->created_at->toDateString() }}">{{ $review->created_at->timezone(config('app.timezone'))->format('M j, Y') }}</time>@endif
                        </div>
                        @if($review->comment)<p>{{ $review->comment }}</p>@endif
                    </li>
                @endforeach
            </ul>
        @endif
    </section>

    @if(($related ?? collect())->isNotEmpty())
        <section class="pdp-rail-wrap">
            <h2>You may also like</h2>
            <div class="pdp-rail">
                @foreach($related as $item)
                    @php $itemVariant = $item->defaultVariant(); $itemImage = $item->primaryImage(); @endphp
                    <a class="s3-tile" href="{{ route('products.show', $item->slug) }}">
                        @if($itemImage)
                            <img src="{{ asset($itemImage->path) }}" alt="{{ $item->name }}">
                        @endif
                        <h6>{{ $item->name }}</h6>
                        @include('partials.product-rating', ['product' => $item])
                        <div class="price">₱{{ number_format($itemVariant?->price ?? 0, 2) }}
                            @if($itemVariant?->compare_at_price)<span class="compare">₱{{ number_format($itemVariant->compare_at_price, 2) }}</span>@endif
                        </div>
                        <span class="s3-chip">₱{{ number_format($shipping, 0) }} shipping · COD</span>
                    </a>
                @endforeach
            </div>
        </section>
    @endif

    @php
        $storeExtras = ($fromStore ?? collect())->reject(fn ($item) => ($related ?? collect())->contains('id', $item->id));
    @endphp
    @if($storeExtras->isNotEmpty())
        <section class="pdp-rail-wrap">
            <h2>More from {{ $storeName }}</h2>
            <div class="pdp-rail">
                @foreach($storeExtras as $item)
                    @php $itemVariant = $item->defaultVariant(); $itemImage = $item->primaryImage(); @endphp
                    <a class="s3-tile" href="{{ route('products.show', $item->slug) }}">
                        @if($itemImage)
                            <img src="{{ asset($itemImage->path) }}" alt="{{ $item->name }}">
                        @endif
                        <h6>{{ $item->name }}</h6>
                        @include('partials.product-rating', ['product' => $item])
                        <div class="price">₱{{ number_format($itemVariant?->price ?? 0, 2) }}
                            @if($itemVariant?->compare_at_price)<span class="compare">₱{{ number_format($itemVariant->compare_at_price, 2) }}</span>@endif
                        </div>
                        <span class="s3-chip">₱{{ number_format($shipping, 0) }} shipping · COD</span>
                    </a>
                @endforeach
            </div>
        </section>
    @endif
</section>
@endsection
