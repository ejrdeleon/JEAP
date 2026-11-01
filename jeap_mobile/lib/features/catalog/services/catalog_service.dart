import 'package:jeap_mobile/core/network/api_client.dart';
import 'package:jeap_mobile/core/models/product.dart';
import 'package:jeap_mobile/core/models/category.dart';

class CatalogService {
  final ApiClient _api;

  CatalogService({ApiClient? client}) : _api = client ?? const ApiClient();

  Future<List<Product>> fetchProducts({
    String? category,
    int? categoryId,
    String? brand,
    String? query,
    String? search,
    double? minPrice,
    double? maxPrice,
    String? sort,
  }) async {
    final searchTerm = (search != null && search.isNotEmpty)
        ? search
        : ((query != null && query.isNotEmpty) ? query : null);

    final params = [
      if (category != null && category.isNotEmpty) 'category=$category',
      if (categoryId != null) 'category_id=$categoryId',
      if (brand != null && brand.isNotEmpty) 'brand=$brand',
      if (searchTerm != null) 'search=${Uri.encodeComponent(searchTerm)}',
      if (minPrice != null) 'min_price=$minPrice',
      if (maxPrice != null) 'max_price=$maxPrice',
      if (sort != null && sort.isNotEmpty) 'sort=$sort',
    ].join('&');

    final path = params.isEmpty ? '/products' : '/products?$params';
    final res = await _api.get(path);
    final list = (res is Map && res.containsKey('data'))
        ? res['data'] as List
        : (res is Map && res.containsKey('products'))
            ? res['products'] as List
            : (res as List? ?? []);
    return list
        .whereType<Map>()
        .map((e) => Product.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Product> fetchProduct(String idOrSlug) async {
    final res = await _api.get('/products/$idOrSlug');
    final data =
        (res is Map && res.containsKey('product')) ? res['product'] : (res is Map && res.containsKey('data') ? res['data'] : res);
    return Product.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<List<ProductCategory>> fetchCategories() async {
    final res = await _api.get('/categories');
    final list = (res is Map && res.containsKey('data'))
        ? res['data'] as List
        : (res as List? ?? []);
    return list
        .whereType<Map>()
        .map((e) => ProductCategory.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchBrands() async {
    final res = await _api.get('/brands');
    final list = (res is Map && res.containsKey('data'))
        ? res['data'] as List
        : (res as List? ?? []);
    return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> fetchHome() async {
    final res = await _api.get('/home');
    return res as Map<String, dynamic>;
  }
}
