import 'package:jeap_mobile/core/models/category.dart';
import 'package:jeap_mobile/core/models/product.dart';

const sampleCategories = <ProductCategory>[
  ProductCategory(id: 'laptops', name: 'Laptops', icon: 'laptop'),
  ProductCategory(id: 'phones', name: 'Cell Phones', icon: 'phone'),
];

const sampleProducts = <Product>[
  Product(
    id: 'p1',
    name: 'MacBook Air M2',
    price: 999,
    category: 'laptops',
    imageUrl: 'images/categories/cat-computers.png',
  ),
  Product(
    id: 'p2',
    name: 'iPhone 15 Pro',
    price: 1099,
    category: 'phones',
    imageUrl: 'images/categories/cat-mobiles.png',
  ),
];
