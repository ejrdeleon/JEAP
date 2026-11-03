@if(($product->reviews_count ?? 0) > 0)
    <p class="s3-rating">★ {{ number_format((float) $product->reviews_avg_rating, 1) }} · {{ $product->reviews_count }}</p>
@endif
