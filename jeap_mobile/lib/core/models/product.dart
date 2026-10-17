class Product {
  final String id;
  final String name;
  final String? slug;
  final double price;
  final double? compareAtPrice;
  final double rating;
  final int reviewCount;
  final String? imageUrl;
  final bool isNew;
  final bool isFeatured;
  final bool freeShipping;
  final bool inStock;
  final int stock;
  final String? brand;
  final String? sku;
  final String? category;
  final String? description;
  final List<String> colors;
  final int? variantId;
  final Map<String, int> variantIdsByColor;
  final Map<String, int> stocksByColor;

  const Product({
    required this.id,
    required this.name,
    this.slug,
    required this.price,
    this.compareAtPrice,
    this.rating = 0,
    this.reviewCount = 0,
    this.imageUrl,
    this.isNew = false,
    this.isFeatured = false,
    this.freeShipping = true,
    this.inStock = true,
    this.stock = 10,
    this.brand,
    this.sku,
    this.category,
    this.description,
    this.colors = const [],
    this.variantId,
    this.variantIdsByColor = const {},
    this.stocksByColor = const {},
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    List<String> colors = [];
    final variants = (json['variants'] as List? ?? [])
        .whereType<Map>()
        .map((variant) => Map<String, dynamic>.from(variant))
        .toList();
    final variantIdsByColor = <String, int>{};
    final stocksByColor = <String, int>{};
    for (final variant in variants) {
      final color = variant['color']?.toString();
      final id = (variant['id'] as num?)?.toInt();
      if (color != null && color.isNotEmpty && id != null) {
        colors.add(color);
        variantIdsByColor[color] = id;
        stocksByColor[color] = (variant['stock'] as num?)?.toInt() ?? 0;
      }
    }
    colors = colors.toSet().toList();
    if (json['colors'] is List) {
      colors = (json['colors'] as List).map((e) => e.toString()).toList();
    }

    final defaultVariant = variants.isEmpty ? null : variants.first;
    final stockVal = (json['stock'] as num?)?.toInt() ??
        (defaultVariant?['stock'] as num?)?.toInt() ??
        (json['in_stock'] == false ? 0 : 10);

    return Product(
      id: (json['product_id'] ?? json['id']).toString(),
      name: (json['product_name'] ?? json['name'] ?? '') as String,
      slug: json['slug'] as String?,
      price: (json['price'] as num?)?.toDouble() ??
          (defaultVariant?['price'] as num?)?.toDouble() ??
          0.0,
      compareAtPrice: (json['compare_at_price'] as num?)?.toDouble() ??
          (defaultVariant?['compare_at_price'] as num?)?.toDouble(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      imageUrl: (json['image_url'] ?? json['image']) as String?,
      isNew: json['is_new'] as bool? ?? false,
      isFeatured: json['is_featured'] as bool? ?? false,
      freeShipping: json['free_shipping'] as bool? ?? true,
      inStock: json['in_stock'] as bool? ?? (stockVal > 0),
      stock: stockVal,
      brand: json['brand'] as String?,
      sku: (json['sku'] ?? defaultVariant?['sku']) as String?,
      category: (json['category'] is Map
          ? json['category']['name']
          : json['category']) as String?,
      description: json['description'] as String?,
      colors: colors,
      variantId: (json['variant_id'] as num?)?.toInt() ??
          (defaultVariant?['id'] as num?)?.toInt(),
      variantIdsByColor: variantIdsByColor,
      stocksByColor: stocksByColor,
    );
  }
}
