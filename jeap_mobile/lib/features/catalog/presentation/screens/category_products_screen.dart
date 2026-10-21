import 'package:flutter/material.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/core/widgets/jeap_app_bar.dart';
import 'package:jeap_mobile/core/widgets/product_card.dart';
import 'package:jeap_mobile/core/models/category.dart';
import 'package:jeap_mobile/core/models/product.dart';
import 'package:jeap_mobile/features/catalog/services/catalog_service.dart';
import 'package:jeap_mobile/features/catalog/presentation/screens/product_detail_screen.dart';

class CategoryProductsScreen extends StatefulWidget {
  final ProductCategory category;
  const CategoryProductsScreen({super.key, required this.category});

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  final _catalogService = CatalogService();
  List<Product> _products = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final categoryKey = widget.category.slug ?? widget.category.id;
      final products =
          await _catalogService.fetchProducts(category: categoryKey);
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Could not load products for this category.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _products
        .where((p) =>
            _searchQuery.isEmpty ||
            p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const JeapAppBar(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadProducts,
          color: AppTheme.jeapPurple,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(widget.category.name,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search in ${widget.category.name}...',
                    prefixIcon: const Icon(Icons.search,
                        color: AppTheme.textSecondary, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                  ),
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.jeapPurple),
                      )
                    : _error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_error!,
                                    style: const TextStyle(
                                        color: AppTheme.textSecondary)),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: _loadProducts,
                                  icon: const Icon(Icons.refresh, size: 18),
                                  label: const Text('Retry'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.jeapPurple,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : filtered.isEmpty
                            ? Center(
                                child: Text(
                                  _searchQuery.isEmpty
                                      ? 'No products in this category yet.'
                                      : 'No products match "$_searchQuery".',
                                  style: const TextStyle(
                                      color: AppTheme.textSecondary),
                                ),
                              )
                            : GridView.builder(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                physics: const AlwaysScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.72,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                                itemCount: filtered.length,
                                itemBuilder: (_, i) => ProductCard(
                                  product: filtered[i],
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProductDetailScreen(
                                          product: filtered[i]),
                                    ),
                                  ),
                                ),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
