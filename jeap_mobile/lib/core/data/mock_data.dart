import 'package:jeap_mobile/core/models/category.dart';
import 'package:jeap_mobile/core/models/product.dart';

/// TEMPORARY mock data so the buyer UI is navigable before the Laravel
/// API exists. Every value here (names, prices, icons) is a placeholder
/// pulled straight from the Figma reference — swap this whole file for
/// a real repository (e.g. ProductRepository hitting GET /api/products)
/// once the backend is up. Do not treat these as real catalog data.
class MockData {
  static const categories = <ProductCategory>[
    ProductCategory(id: 'laptops', name: 'Laptops', icon: 'laptop'),
    ProductCategory(id: 'pc', name: 'PC & Computers', icon: 'desktop'),
    ProductCategory(id: 'phones', name: 'Cell Phones', icon: 'phone'),
    ProductCategory(id: 'tablets', name: 'Tablets', icon: 'tablet'),
    ProductCategory(id: 'gaming', name: 'Gaming & VR', icon: 'gaming'),
    ProductCategory(id: 'networks', name: 'Networks', icon: 'network'),
    ProductCategory(id: 'cameras', name: 'Cameras', icon: 'camera'),
    ProductCategory(id: 'sounds', name: 'Sounds', icon: 'sound'),
    ProductCategory(id: 'office', name: 'Office', icon: 'office'),
  ];

  static const topCategories = <ProductCategory>[
    ProductCategory(id: 'laptops', name: 'Laptops', icon: 'laptop'),
    ProductCategory(id: 'pc', name: 'PC', icon: 'desktop'),
    ProductCategory(id: 'phones', name: 'Phones', icon: 'phone'),
    ProductCategory(id: 'tablets', name: 'Tablets', icon: 'tablet'),
    ProductCategory(id: 'gaming', name: 'Gaming', icon: 'gaming'),
    ProductCategory(id: 'cameras', name: 'Cameras', icon: 'camera'),
  ];

  static const products = <Product>[
    Product(
      id: 'p1',
      name: 'MacBook Air M2',
      price: 999.00,
      rating: 4.8,
      reviewCount: 120,
      isNew: true,
      category: 'laptops',
      imageUrl: 'images/categories/cat-computers.png',
      description: 'Apple M2 chip, thin and light laptop.',
    ),
    Product(
      id: 'p2',
      name: 'Sony WH-1000XM5',
      price: 349.00,
      rating: 4.8,
      reviewCount: 89,
      isNew: true,
      category: 'sounds',
      imageUrl: 'images/categories/cat-audios.png',
      description: 'Wireless Noise Cancelling Headphones',
      colors: ['black', 'silver', 'navy'],
    ),
    Product(
      id: 'p3',
      name: 'iPhone 15 Pro',
      price: 1099.00,
      rating: 4.8,
      reviewCount: 120,
      category: 'phones',
      imageUrl: 'images/categories/cat-mobiles.png',
    ),
    Product(
      id: 'p4',
      name: 'Dell XPS 13',
      price: 899.00,
      rating: 4.8,
      reviewCount: 120,
      category: 'laptops',
      imageUrl: 'images/categories/cat-computers.png',
    ),
    Product(
      id: 'p5',
      name: 'Canon EOS R50',
      price: 649.00,
      rating: 4.8,
      reviewCount: 120,
      category: 'cameras',
      imageUrl: 'images/categories/cat-cameras.png',
    ),
    Product(
      id: 'p6',
      name: 'Logitech G Pro X',
      price: 129.00,
      rating: 4.8,
      reviewCount: 120,
      category: 'gaming',
      imageUrl: 'images/categories/cat-gaming.png',
    ),
  ];

  static List<Product> get bestSellers =>
      products.where((p) => p.isNew).toList();
}
