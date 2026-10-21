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
  final String? categorySlug;
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
    this.categorySlug,
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
      final id = (variant['id'] as num?)?.toInt() ??
          int.tryParse(variant['id']?.toString() ?? '');
      if (color != null && color.isNotEmpty && id != null) {
        colors.add(color);
        variantIdsByColor[color] = id;
        stocksByColor[color] = (variant['stock'] as num?)?.toInt() ??
            int.tryParse(variant['stock']?.toString() ?? '') ??
            0;
      }
    }
    colors = colors.toSet().toList();
    if (json['colors'] is List) {
      colors = (json['colors'] as List).map((e) => e.toString()).toList();
    }

    final defaultVariant = variants.isEmpty ? null : variants.first;
    final stockVal = (json['stock'] as num?)?.toInt() ??
        int.tryParse(json['stock']?.toString() ?? '') ??
        (defaultVariant?['stock'] as num?)?.toInt() ??
        int.tryParse(defaultVariant?['stock']?.toString() ?? '') ??
        (json['in_stock'] == false ? 0 : 10);

    double parseDouble(dynamic v, [double fallback = 0.0]) {
      if (v == null) return fallback;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? fallback;
    }

    double? parseOptionalDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    String? imageUrl = (json['image_url'] ?? json['image']) as String?;
    if (imageUrl == null || imageUrl.isEmpty) {
      final images = json['images'] as List?;
      if (images != null && images.isNotEmpty) {
        final firstImg = images.first;
        if (firstImg is Map && firstImg['path'] != null) {
          imageUrl = firstImg['path'].toString();
        }
      }
    }
    if (imageUrl != null &&
        imageUrl.isNotEmpty &&
        !imageUrl.startsWith('http://') &&
        !imageUrl.startsWith('https://')) {
      final cleanPath =
          imageUrl.startsWith('/') ? imageUrl.substring(1) : imageUrl;
      imageUrl = 'http://127.0.0.1:8080/$cleanPath';
    }

    final categoryObj = json['category'];
    String? categoryName;
    String? categorySlug;
    if (categoryObj is Map) {
      categoryName = categoryObj['name']?.toString();
      categorySlug = categoryObj['slug']?.toString();
    } else if (categoryObj != null) {
      categoryName = categoryObj.toString();
    }

    return Product(
      id: (json['product_id'] ?? json['id']).toString(),
      name: (json['product_name'] ?? json['name'] ?? '') as String,
      slug: json['slug'] as String?,
      price: parseDouble(json['price'] ?? defaultVariant?['price']),
      compareAtPrice: parseOptionalDouble(
          json['compare_at_price'] ?? defaultVariant?['compare_at_price']),
      rating: parseDouble(json['rating']),
      reviewCount: (json['review_count'] as num?)?.toInt() ??
          int.tryParse(json['review_count']?.toString() ?? '') ??
          0,
      imageUrl: imageUrl,
      isNew: json['is_new'] as bool? ?? false,
      isFeatured: json['is_featured'] as bool? ?? false,
      freeShipping: json['free_shipping'] as bool? ?? true,
      inStock: json['in_stock'] as bool? ?? (stockVal > 0),
      stock: stockVal,
      brand: json['brand'] as String?,
      sku: (json['sku'] ?? defaultVariant?['sku']) as String?,
      category: categoryName,
      categorySlug: categorySlug,
      description: json['description'] as String?,
      colors: colors,
      variantId: (json['variant_id'] as num?)?.toInt() ??
          (defaultVariant?['id'] as num?)?.toInt() ??
          int.tryParse(defaultVariant?['id']?.toString() ?? ''),
      variantIdsByColor: variantIdsByColor,
      stocksByColor: stocksByColor,
    );
  }
}
