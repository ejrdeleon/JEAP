import 'package:flutter/material.dart';

/// MockData stores icons as plain strings so it stays JSON-shaped like
/// a future API response.  This maps those keys to real Material icons
/// for now — replace with real category icon assets/URLs once the
/// backend provides them.
IconData categoryIcon(String key) {
  switch (key) {
    case 'laptop':
      return Icons.laptop_mac_outlined;
    case 'desktop':
      return Icons.desktop_windows_outlined;
    case 'phone':
      return Icons.smartphone_outlined;
    case 'tablet':
      return Icons.tablet_mac_outlined;
    case 'gaming':
      return Icons.sports_esports_outlined;
    case 'network':
      return Icons.wifi_outlined;
    case 'camera':
      return Icons.camera_alt_outlined;
    case 'sound':
      return Icons.headphones_outlined;
    case 'office':
      return Icons.print_outlined;
    default:
      return Icons.category_outlined;
  }
}
