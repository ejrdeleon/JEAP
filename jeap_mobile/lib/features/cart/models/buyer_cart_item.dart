class BuyerCartItem {
  final int id;
  final String productId;
  final int? variantId;
  final String productName;
  final String? imageUrl;
  final double price;
  int quantity;
  final Map<String, String> variations;
  final String? sellerName;
  bool selected;

  BuyerCartItem({
    required this.id,
    required this.productId,
    this.variantId,
    required this.productName,
    required this.price,
    required this.quantity,
    this.imageUrl,
    this.variations = const {},
    this.sellerName,
    this.selected = true,
  });

  double get subtotal => price * quantity;

  factory BuyerCartItem.fromJson(Map<String, dynamic> json) {
    Map<String, String> variations = {};
    if (json['variations'] is Map) {
      variations = (json['variations'] as Map)
          .map((k, v) => MapEntry(k.toString(), v.toString()));
    } else {
      for (final key in ['color', 'size']) {
        if (json[key] != null && json[key].toString().isNotEmpty) {
          variations[key == 'color' ? 'Color' : 'Size'] = json[key].toString();
        }
      }
      if (variations.isEmpty &&
          json['variant'] != null &&
          json['variant'].toString().isNotEmpty) {
        variations = {'Variant': json['variant'].toString()};
      }
    }

    return BuyerCartItem(
      id: json['id'] as int,
      productId: (json['product_id'] ?? '').toString(),
      variantId: (json['variant_id'] as num?)?.toInt(),
      productName: (json['product_name'] ?? json['name'] ?? '') as String,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      imageUrl: (json['image_url'] ?? json['image']) as String?,
      variations: variations,
      sellerName: json['seller_name'] as String?,
    );
  }

  factory BuyerCartItem.fromApi(Map<String, dynamic> json) =>
      BuyerCartItem.fromJson(json);
}
