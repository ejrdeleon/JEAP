import 'package:jeap_mobile/core/network/api_client.dart';
import 'package:jeap_mobile/core/models/product.dart';
import 'package:jeap_mobile/core/models/category.dart';

class CatalogService {
  final ApiClient _api;

  CatalogService({ApiClient? client}) : _api = client ?? const ApiClient();

  Future<List<Product>> fetchProducts({
    String? category,
    String? brand,
    String? query,
  }) async {
    final params = [
      if (category != null && category.isNotEmpty) 'category=$category',
      if (brand != null && brand.isNotEmpty) 'brand=$brand',
      if (query != null && query.isNotEmpty) 'q=$query',
    ].join('&');
    final path = params.isEmpty ? '/products' : '/products?$params';
    final res = await _api.get(path);
    final list = (res is Map && res.containsKey('data'))
        ? res['data'] as List
        : (res as List? ?? []);
    return list
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Product> fetchProduct(String slug) async {
    final res = await _api.get('/products/$slug');
    final data =
        (res is Map && res.containsKey('product')) ? res['product'] : res;
    return Product.fromJson(data as Map<String, dynamic>);
  }

  Future<List<ProductCategory>> fetchCategories() async {
    final res = await _api.get('/categories') as List;
    return res
        .map((e) => ProductCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchBrands() async {
    final res = await _api.get('/brands') as List;
    return res.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> fetchHome() async {
    final res = await _api.get('/home');
    return res as Map<String, dynamic>;
  }
}
