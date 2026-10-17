class ProductCategory {
  final String id;
  final String name;
  final String icon; // Material icon name key, mapped in the UI layer

  const ProductCategory({
    required this.id,
    required this.name,
    required this.icon,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'].toString(),
      name: json['name'] as String,
      icon: json['icon'] as String? ?? 'category',
    );
  }
}
