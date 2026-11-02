import 'package:flutter/material.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/core/widgets/jeap_app_bar.dart';
import 'package:jeap_mobile/core/widgets/product_card.dart';
import 'package:jeap_mobile/core/data/mock_data.dart';
import 'package:jeap_mobile/core/models/category.dart';
import 'package:jeap_mobile/features/catalog/presentation/screens/product_detail_screen.dart';

class CategoryProductsScreen extends StatefulWidget {
  final ProductCategory category;
  const CategoryProductsScreen({super.key, required this.category});

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final products = MockData.products
        .where((p) =>
            p.category == widget.category.id &&
            (_searchQuery.isEmpty ||
                p.name.toLowerCase().contains(_searchQuery.toLowerCase())))
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
              child: products.isEmpty
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
