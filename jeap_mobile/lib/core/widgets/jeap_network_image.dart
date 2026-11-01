import 'package:flutter/material.dart';
import 'package:jeap_mobile/core/network/api_config.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';

/// Centralized, high-performance image loading widget for JEAP Mobile.
///
/// Features:
/// 1. Dynamic endpoint & path resolution (supports absolute URLs, relative media,
///    storage paths, localhost, Wi-Fi IP, and ADB reverse proxy).
/// 2. Memory optimization via [cacheWidth] and [cacheHeight] decoding downsampling.
/// 3. In-flight loading placeholders and customizable fallback error widgets.
/// 4. Cache-busting support for mutable entities (e.g. user profile photos)
///    using [ApiConfig.avatarVersion].
class JeapNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final int? cacheWidth;
  final int? cacheHeight;
  final BorderRadius? borderRadius;
  final Widget? fallback;
  final bool cacheBust;

  const JeapNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.cacheWidth,
    this.cacheHeight,
    this.borderRadius,
    this.fallback,
    this.cacheBust = false,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = ApiConfig.resolveImageUrl(imageUrl, cacheBust: cacheBust);
    final placeholder = fallback ??
        Center(
          child: Icon(
            Icons.image_outlined,
            color: AppTheme.textSecondary.withValues(alpha: 0.6),
            size: 28,
          ),
        );

    Widget child;
    if (resolvedUrl == null || resolvedUrl.isEmpty) {
      child = placeholder;
    } else {
      // Calculate sensible downsampled cache dimensions if none explicitly passed
      final int? effectiveCacheWidth = cacheWidth ??
          (width != null && width! > 0 && width!.isFinite
              ? (width! * 2.2).round().clamp(50, 1400)
              : null);
      final int? effectiveCacheHeight = cacheHeight ??
          (height != null && height! > 0 && height!.isFinite
              ? (height! * 2.2).round().clamp(50, 1400)
              : null);

      child = Image.network(
        resolvedUrl,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: effectiveCacheWidth,
        cacheHeight: effectiveCacheHeight,
        loadingBuilder: (context, currentChild, progress) {
          if (progress == null) return currentChild;
          return Container(
            width: width,
            height: height,
            color: AppTheme.inputFill,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.jeapPurple,
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => placeholder,
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: child,
      );
    }

    return child;
  }
}
