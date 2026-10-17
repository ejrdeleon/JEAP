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
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    List<String> colors = [];
    if (json['colors'] is List) {
      colors = (json['colors'] as List).map((e) => e.toString()).toList();
    } else if (json['variants'] is List) {
      for (final v in json['variants']) {
        if (v is Map &&
            v['color'] != null &&
            v['color'].toString().isNotEmpty) {
          colors.add(v['color'].toString());
        }
      }
    }

    final stockVal = (json['stock'] as num?)?.toInt() ??
        (json['in_stock'] == false ? 0 : 10);

    return Product(
      id: json['id'].toString(),
      name: (json['product_name'] ?? json['name'] ?? '') as String,
      slug: json['slug'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      compareAtPrice: (json['compare_at_price'] as num?)?.toDouble(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      imageUrl: (json['image_url'] ?? json['image']) as String?,
      isNew: json['is_new'] as bool? ?? false,
      isFeatured: json['is_featured'] as bool? ?? false,
      freeShipping: json['free_shipping'] as bool? ?? true,
      inStock: json['in_stock'] as bool? ?? (stockVal > 0),
      stock: stockVal,
      brand: json['brand'] as String?,
      sku: json['sku'] as String?,
      category: (json['category'] is Map
          ? json['category']['name']
          : json['category']) as String?,
      description: json['description'] as String?,
      colors: colors,
    );
  }
}
