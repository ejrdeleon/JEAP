import 'package:flutter/material.dart';

IconData categoryIcon(String key) {
  final clean = key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  switch (clean) {
    case 'laptop':
    case 'laptops':
      return Icons.laptop_mac_outlined;
    case 'pc':
    case 'desktop':
    case 'computers':
    case 'computer':
      return Icons.desktop_windows_outlined;
    case 'phone':
    case 'phones':
    case 'mobiles':
    case 'mobile':
      return Icons.smartphone_outlined;
    case 'tablet':
    case 'tablets':
      return Icons.tablet_mac_outlined;
    case 'gaming':
    case 'gamingvr':
      return Icons.sports_esports_outlined;
    case 'sportequip':
    case 'sportsequip':
    case 'sports':
      return Icons.fitness_center_outlined;
    case 'kitchen':
      return Icons.kitchen_outlined;
    case 'robotcleaner':
      return Icons.cleaning_services_outlined;
    case 'network':
    case 'networks':
      return Icons.wifi_outlined;
    case 'camera':
    case 'cameras':
      return Icons.camera_alt_outlined;
    case 'sound':
    case 'sounds':
    case 'audios':
    case 'audio':
      return Icons.headphones_outlined;
    case 'televisions':
    case 'television':
    case 'tv':
      return Icons.tv_outlined;
    case 'office':
      return Icons.print_outlined;
    default:
      return Icons.category_outlined;
  }
}
