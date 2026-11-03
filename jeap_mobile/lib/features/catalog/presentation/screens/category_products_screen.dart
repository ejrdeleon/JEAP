import 'package:flutter/material.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/core/widgets/jeap_app_bar.dart';
import 'package:jeap_mobile/core/widgets/product_card.dart';
import 'package:jeap_mobile/core/models/category.dart';
import 'package:jeap_mobile/core/models/product.dart';
import 'package:jeap_mobile/features/catalog/presentation/screens/product_detail_screen.dart';
import 'package:jeap_mobile/features/catalog/services/catalog_service.dart';

class CategoryProductsScreen extends StatefulWidget {
  final ProductCategory category;
  final List<Product>? initialProducts;
  const CategoryProductsScreen({
    super.key,
    required this.category,
    this.initialProducts,
  });

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  final CatalogService _catalogService = CatalogService();
  String _searchQuery = '';
  List<Product> _products = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialProducts != null) {
      _products = widget.initialProducts!;
      _loading = false;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final categoryId = int.tryParse(widget.category.id);
      final items = await _catalogService.fetchProducts(
        category: widget.category.slug ?? widget.category.id,
        categoryId: categoryId,
      );
      if (!mounted) return;
      setState(() {
        _products = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load products. Check your connection and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = _products
        .where((p) =>
            _searchQuery.isEmpty ||
            p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= 900 ? 4 : (width >= 600 ? 3 : 2);
    final childAspectRatio = width < 360 ? 0.56 : (width < 600 ? 0.58 : 0.65);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const JeapAppBar(),
      body: SafeArea(
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
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.jeapPurple),
                    )
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: AppTheme.textSecondary),
                                ),
                                const SizedBox(height: 12),
                                TextButton(onPressed: _load, child: const Text('Retry')),
                              ],
                            ),
                          ),
                        )
                      : products.isEmpty
                          ? const Center(
                              child: Text('No products found.',
                                  style: TextStyle(color: AppTheme.textSecondary)))
                          : GridView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                childAspectRatio: childAspectRatio,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: products.length,
                              itemBuilder: (_, i) => ProductCard(
                                product: products[i],
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          ProductDetailScreen(product: products[i])),
                                ),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
