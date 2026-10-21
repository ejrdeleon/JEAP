import 'package:flutter/material.dart';

/// Renders the official JEAP logo asset with clean scaling and aspect ratio preservation.
class JeapLogo extends StatelessWidget {
  final double height;
  final double? width;
  final BoxFit fit;

  const JeapLogo({
    super.key,
    this.height = 40,
    this.width,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/jeap_logo.png',
      height: height,
      width: width,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        // Fallback gracefully if asset is still loading
        return Text(
          'JEAP',
          style: TextStyle(
            fontSize: height * 0.5,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF4F46E5),
          ),
        );
      },
    );
  }
}
