import 'dart:async';
import 'package:flutter/material.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/core/widgets/product_card.dart';
import 'package:jeap_mobile/core/models/product.dart';
import 'package:jeap_mobile/core/models/category.dart';
import 'package:jeap_mobile/features/catalog/services/catalog_service.dart';
import 'package:jeap_mobile/features/catalog/presentation/screens/product_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final CatalogService _catalogService = CatalogService();
  Timer? _debounceTimer;
  int _searchSequence = 0;

  List<Product> _results = [];
  List<ProductCategory> _categories = [];
  bool _isLoading = false;
  String _query = '';
  String? _errorMessage;

  String _selectedSort = ''; // '', 'latest', 'price_low_high', 'price_high_low'
  int? _selectedCategoryId;
  double? _minPrice;
  double? _maxPrice;

  final List<String> _popularKeywords = const [
    'MacBook',
    'Laptop',
    'Smartphone',
    'Espresso',
    'Camera',
    'Vacuum',
    'Speaker',
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _ctrl.text = widget.initialQuery!;
      _performSearch(widget.initialQuery);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _catalogService.fetchCategories();
      if (mounted) {
        setState(() => _categories = cats);
      }
    } catch (_) {}
  }

  void _onQueryChanged(String val) {
    _debounceTimer?.cancel();
    if (val.trim().isEmpty) {
      setState(() {
        _query = '';
        _results = [];
        _errorMessage = null;
        _isLoading = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _performSearch(val);
    });
  }

  Future<void> _performSearch([String? newQuery]) async {
    _debounceTimer?.cancel();
    final q = (newQuery ?? _ctrl.text).trim();
    _query = q;

    final currentSeq = ++_searchSequence;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _catalogService.fetchProducts(
        search: q.isNotEmpty ? q : null,
        categoryId: _selectedCategoryId,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        sort: _selectedSort.isNotEmpty ? _selectedSort : null,
      );

      if (!mounted || currentSeq != _searchSequence) return;

      setState(() {
        _results = items;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted || currentSeq != _searchSequence) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load products. Check your connection and try again.';
      });
    }
  }

  void _clearSearch() {
    _debounceTimer?.cancel();
    _ctrl.clear();
    setState(() {
      _query = '';
      _results = [];
      _errorMessage = null;
      _isLoading = false;
    });
  }

  void _showFilterSheet() {
    final minCtrl = TextEditingController(
        text: _minPrice != null ? _minPrice!.toInt().toString() : '');
    final maxCtrl = TextEditingController(
        text: _maxPrice != null ? _maxPrice!.toInt().toString() : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Filter Products',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      minCtrl.clear();
                      maxCtrl.clear();
                      setState(() {
                        _minPrice = null;
                        _maxPrice = null;
                      });
                      Navigator.pop(ctx);
                      _performSearch();
                    },
                    child: const Text('Reset',
                        style: TextStyle(color: Colors.redAccent)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Price Range (₱)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: minCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Min Price',
                        prefixText: '₱',
                        isDense: true,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('–'),
                  ),
                  Expanded(
                    child: TextField(
                      controller: maxCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Max Price',
                        prefixText: '₱',
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final tempMin = double.tryParse(minCtrl.text.trim());
                    final tempMax = double.tryParse(maxCtrl.text.trim());
                    setState(() {
                      _minPrice = tempMin;
                      _maxPrice = tempMax;
                    });
                    Navigator.pop(ctx);
                    _performSearch();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.jeapPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.buyerRadius),
                    ),
                  ),
                  child: const Text('Apply Filters',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= 900 ? 4 : (width >= 600 ? 3 : 2);
    final childAspectRatio = width < 360 ? 0.56 : (width < 600 ? 0.58 : 0.65);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: const BackButton(color: AppTheme.textPrimary),
        title: TextField(
          controller: _ctrl,
          autofocus: widget.initialQuery == null || widget.initialQuery!.isEmpty,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _performSearch(),
          onChanged: _onQueryChanged,
          decoration: InputDecoration(
            hintText: 'Search products (e.g. MacBook)...',
            prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
            border: InputBorder.none,
            filled: false,
            suffixIcon: _ctrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: _clearSearch,
                  )
                : null,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.tune,
              color: (_minPrice != null || _maxPrice != null)
                  ? AppTheme.jeapPurple
                  : AppTheme.textPrimary,
            ),
            tooltip: 'Filter',
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Category & Sort bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  PopupMenuButton<String>(
                    onSelected: (val) {
                      setState(() => _selectedSort = val);
                      _performSearch();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _selectedSort.isNotEmpty
                            ? AppTheme.jeapPurple.withValues(alpha: 0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _selectedSort.isNotEmpty
                              ? AppTheme.jeapPurple
                              : AppTheme.borderColor,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.sort,
                            size: 16,
                            color: _selectedSort.isNotEmpty
                                ? AppTheme.jeapPurple
                                : AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _selectedSort == 'price_low_high'
                                ? 'Price: Low'
                                : _selectedSort == 'price_high_low'
                                    ? 'Price: High'
                                    : _selectedSort == 'latest'
                                        ? 'Latest'
                                        : 'Sort',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _selectedSort.isNotEmpty
                                  ? AppTheme.jeapPurple
                                  : AppTheme.textPrimary,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, size: 16),
                        ],
                      ),
                    ),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: '', child: Text('Default Order')),
                      PopupMenuItem(value: 'latest', child: Text('Latest Arrivals')),
                      PopupMenuItem(value: 'price_low_high', child: Text('Price: Low to High')),
                      PopupMenuItem(value: 'price_high_low', child: Text('Price: High to Low')),
                    ],
                  ),
                  const SizedBox(width: 8),
                  // Categories chips
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text('All', style: TextStyle(fontSize: 12)),
                            selected: _selectedCategoryId == null,
                            selectedColor: AppTheme.jeapPurple.withValues(alpha: 0.15),
                            onSelected: (sel) {
                              setState(() => _selectedCategoryId = null);
                              _performSearch();
                            },
                          ),
                          const SizedBox(width: 6),
                          ..._categories.map((cat) {
                            final catId = int.tryParse(cat.id);
                            final isSel = _selectedCategoryId == catId;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(cat.name, style: const TextStyle(fontSize: 12)),
                                selected: isSel,
                                selectedColor: AppTheme.jeapPurple.withValues(alpha: 0.15),
                                onSelected: (sel) {
                                  setState(() {
                                    _selectedCategoryId = sel ? catId : null;
                                  });
                                  _performSearch();
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Body Result States
            Expanded(
              child: _buildBody(crossAxisCount, childAspectRatio),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(int crossAxisCount, double childAspectRatio) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppTheme.jeapPurple),
            const SizedBox(height: 16),
            Text(
              'Searching products${_query.isNotEmpty ? ' for "$_query"' : ''}...',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_rounded, size: 54, color: Colors.orange.shade400),
              const SizedBox(height: 16),
              const Text(
                'Unable to load products',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () => _performSearch(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry Search'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.jeapPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.buyerRadius),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_query.isEmpty && _selectedCategoryId == null && _results.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_rounded,
                  size: 56, color: AppTheme.jeapPurple.withValues(alpha: 0.2)),
              const SizedBox(height: 16),
              const Text(
                'Search JEAP Products',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              const SizedBox(height: 6),
              const Text(
                'Search through authentic catalog items and verified sellers.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('POPULAR SEARCHES',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: AppTheme.textSecondary)),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _popularKeywords.map((keyword) {
                  return ActionChip(
                    label: Text(keyword, style: const TextStyle(fontSize: 12)),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppTheme.borderColor),
                    avatar: const Icon(Icons.trending_up, size: 14, color: AppTheme.jeapPurple),
                    onPressed: () {
                      _ctrl.text = keyword;
                      _performSearch(keyword);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded,
                  size: 56, color: AppTheme.textSecondary.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              Text(
                _query.isNotEmpty
                    ? 'No products found for "$_query"'
                    : 'No products match your filters',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 6),
              const Text(
                'Try checking your spelling, using more general keywords, or resetting filters.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              if (_minPrice != null || _maxPrice != null || _selectedCategoryId != null) ...[
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _minPrice = null;
                      _maxPrice = null;
                      _selectedCategoryId = null;
                    });
                    _performSearch();
                  },
                  child: const Text('Reset All Filters'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _performSearch,
      color: AppTheme.jeapPurple,
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _results.length,
        itemBuilder: (_, i) => ProductCard(
          product: _results[i],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: _results[i]),
            ),
          ),
        ),
      ),
    );
  }
}
