class ProductCategory {
  final String id;
  final String name;
  final String? slug;
  final String icon;

  const ProductCategory({
    required this.id,
    required this.name,
    this.slug,
    required this.icon,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    final slug = json['slug'] as String?;
    return ProductCategory(
      id: json['id'].toString(),
      name: json['name'] as String,
      slug: slug,
      icon: (json['icon'] as String?) ?? slug ?? 'category',
    );
  }
}
