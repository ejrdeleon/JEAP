import 'package:flutter/material.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/core/widgets/product_card.dart';
import 'package:jeap_mobile/core/models/product.dart';
import 'package:jeap_mobile/features/catalog/services/catalog_service.dart';
import 'package:jeap_mobile/features/catalog/presentation/screens/product_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  final _catalogService = CatalogService();
  List<Product> _results = [];
  bool _isLoading = false;
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _query = '';
        _results = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _query = trimmed;
      _isLoading = true;
    });

    try {
      final items = await _catalogService.fetchProducts(query: trimmed);
      if (mounted && _query == trimmed) {
        setState(() {
          _results = items;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted && _query == trimmed) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: const BackButton(color: AppTheme.textPrimary),
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          onChanged: _performSearch,
          decoration: InputDecoration(
            hintText: 'Search products in database...',
            border: InputBorder.none,
            filled: false,
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _ctrl.clear();
                      _performSearch('');
                    },
                  )
                : null,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.jeapPurple),
              )
            : _query.isEmpty
                ? const Center(
                    child: Text('Type a product name to search.',
                        style: TextStyle(color: AppTheme.textSecondary)),
                  )
                : _results.isEmpty
                    ? Center(
                        child: Text('No products found for "$_query".',
                            style:
                                const TextStyle(color: AppTheme.textSecondary)),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _results.length,
                        itemBuilder: (_, i) => ProductCard(
                          product: _results[i],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProductDetailScreen(product: _results[i]),
                            ),
                          ),
                        ),
                      ),
      ),
    );
  }
}
