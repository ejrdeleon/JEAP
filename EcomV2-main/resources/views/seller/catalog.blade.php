@extends('layouts.dashboard')
@section('title', 'Product catalog')
@section('nav')
    <a href="{{ route('seller.dashboard') }}">Overview</a>
    <a class="active" href="{{ route('seller.catalog') }}">Products</a>
    <a href="{{ route('seller.orders') }}">Orders</a>
    <a href="{{ route('seller.promos') }}">Promotions</a>
    <a href="{{ route('seller.shipments') }}">Shipments</a>
@endsection
@section('content')
@php
    $editing = $editingProduct;
    $variant = $editing?->variants->first();
    $image = $editing?->images->first();
@endphp
<div class="seller-page">
    <div class="seller-heading">
        <div><span class="seller-eyebrow">SELLER CENTER / CATALOG</span><h1>{{ $editing ? 'Edit product' : 'Your products' }}</h1><p>Keep your listings, prices, and stock up to date.</p></div>
        @if($editing)<a class="seller-secondary" href="{{ route('seller.catalog') }}">Cancel edit</a>@endif
    </div>
    @if(session('status'))<div class="seller-flash">{{ session('status') }}</div>@endif
    @if($errors->any())<div class="seller-errors"><strong>Please check the product details.</strong><ul>@foreach($errors->all() as $error)<li>{{ $error }}</li>@endforeach</ul></div>@endif

    <section class="seller-panel seller-form-panel">
        <div class="seller-panel-head"><div><h2>{{ $editing ? 'Product details' : 'Add a product' }}</h2><p>Products marked active can appear in the JEAP marketplace.</p></div></div>
        <form class="seller-product-form" method="post" enctype="multipart/form-data" action="{{ $editing ? route('seller.catalog.update', $editing) : route('seller.catalog.store') }}">
            @csrf
            @if($editing) @method('PUT') @endif
            <label class="seller-field seller-field-wide">Product name
                <input name="name" value="{{ old('name', $editing?->name) }}" maxlength="180" required placeholder="e.g. Wireless noise-cancelling headphones">
            </label>
            <label class="seller-field">Category
                <select name="category_id" required><option value="">Choose a category</option>@foreach($categories as $category)<option value="{{ $category->id }}" @selected((string)old('category_id', $editing?->category_id) === (string)$category->id)>{{ $category->name }}</option>@endforeach</select>
            </label>
            <label class="seller-field">Listing status
                <select name="status"><option value="active" @selected(old('status', $editing?->status ?? 'active') === 'active')>Active</option><option value="draft" @selected(old('status', $editing?->status) === 'draft')>Draft</option></select>
            </label>
            <label class="seller-field">Price <span>(PHP)</span>
                <div class="seller-input-prefix"><span>₱</span><input type="number" name="price" min="0.01" step="0.01" value="{{ old('price', $variant?->price) }}" required placeholder="0.00"></div>
            </label>
            <label class="seller-field">Compare-at price <span>(optional)</span>
                <div class="seller-input-prefix"><span>₱</span><input type="number" name="compare_at_price" min="0.01" step="0.01" value="{{ old('compare_at_price', $variant?->compare_at_price) }}" placeholder="0.00"></div>
            </label>
            <label class="seller-field">Available stock
                <input type="number" name="stock" min="0" step="1" value="{{ old('stock', $variant?->stock ?? 0) }}" required>
            </label>
            <label class="seller-field seller-field-wide">Product photo <span>(JPG, PNG or WebP, up to 5 MB)</span>
                <input type="file" name="image" accept="image/jpeg,image/png,image/webp">
                @if($image)<small>Current photo: <a href="{{ asset($image->path) }}" target="_blank" rel="noopener">View image</a></small>@endif
            </label>
            <label class="seller-field seller-field-wide">Description
                <textarea name="description" rows="4" maxlength="10000" placeholder="Tell customers what makes this product useful.">{{ old('description', $editing?->description) }}</textarea>
            </label>
            <div class="seller-form-actions"><button class="seller-primary" type="submit">{{ $editing ? 'Save changes' : 'Add product' }}</button>@if($editing)<a href="{{ route('seller.catalog') }}">Cancel</a>@endif</div>
        </form>
    </section>

    <section class="seller-panel">
        <div class="seller-panel-head"><div><h2>Catalog</h2><p>{{ $products->total() }} {{ str('product')->plural($products->total()) }}</p></div></div>
        @if($products->isEmpty())
            <div class="seller-empty"><span>🛍️</span><strong>No products yet</strong><p>Add your first product to start building your JEAP store.</p></div>
        @else
            <div class="seller-table-wrap"><table class="seller-table"><thead><tr><th>Product</th><th>Category</th><th>Price</th><th>Stock</th><th>Status</th><th>Actions</th></tr></thead><tbody>
                @foreach($products as $product)
                    @php($productVariant = $product->variants->first())
                    <tr>
                        <td><div class="seller-product-cell">@if($product->images->first())<img src="{{ asset($product->images->first()->path) }}" alt="">@else<div class="seller-image-placeholder">JEAP</div>@endif<div><strong>{{ $product->name }}</strong><small>{{ $productVariant?->sku ?? 'No SKU' }}</small></div></div></td>
                        <td>{{ $product->category->name }}</td>
                        <td>{{ $productVariant ? '₱'.number_format((float)$productVariant->price, 2) : '—' }}</td>
                        <td>{{ number_format($productVariant?->stock ?? 0) }}</td>
                        <td><span class="seller-badge {{ $product->status === 'active' ? 'is-active' : '' }}">{{ str($product->status)->title() }}</span></td>
                        <td><div class="seller-actions"><a href="{{ route('seller.catalog.edit', $product) }}">Edit</a>@if($product->status !== 'inactive')<form method="post" action="{{ route('seller.catalog.archive', $product) }}">@csrf @method('DELETE')<button type="submit">Archive</button></form>@endif</div></td>
                    </tr>
                @endforeach
            </tbody></table></div>
            <div class="seller-pagination">{{ $products->links() }}</div>
        @endif
    </section>
</div>
@endsection
