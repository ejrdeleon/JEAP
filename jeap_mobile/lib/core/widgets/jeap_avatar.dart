import 'package:flutter/material.dart';
import 'package:jeap_mobile/core/network/api_config.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';

class JeapAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double radius;
  final VoidCallback? onTap;
  final bool showBorder;
  final Color? borderColor;
  final Color? backgroundColor;
  final Widget? badge;
  final bool cacheBust;

  const JeapAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.radius = 24,
    this.onTap,
    this.showBorder = false,
    this.borderColor,
    this.backgroundColor,
    this.badge,
    this.cacheBust = true,
  });

  String get _initials {
    final n = (name ?? '').trim();
    if (n.isEmpty) return 'J';
    final parts = n.split(' ').where((p) => p.trim().isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: ApiConfig.avatarVersionNotifier,
      builder: (context, avatarVer, _) {
        final effectiveRadius = radius;
        final resolvedUrl = ApiConfig.resolveImageUrl(imageUrl, cacheBust: cacheBust);
        final bgColor = backgroundColor ?? AppTheme.jeapPurple.withValues(alpha: 0.12);

        Widget avatarContent = _buildFallback(effectiveRadius, bgColor);

        if (resolvedUrl != null && resolvedUrl.isNotEmpty) {
          avatarContent = ClipOval(
            child: Image.network(
              resolvedUrl,
              key: ValueKey('${resolvedUrl}_$avatarVer'),
              width: effectiveRadius * 2,
              height: effectiveRadius * 2,
              cacheWidth: (effectiveRadius * 4).round().clamp(60, 400),
              cacheHeight: (effectiveRadius * 4).round().clamp(60, 400),
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: effectiveRadius * 2,
                  height: effectiveRadius * 2,
                  color: bgColor,
                  child: Center(
                    child: SizedBox(
                      width: effectiveRadius * 0.8,
                      height: effectiveRadius * 0.8,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: AppTheme.jeapPurple,
                      ),
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return _buildFallback(effectiveRadius, bgColor);
              },
            ),
          );
        }

        Widget root = Container(
          width: effectiveRadius * 2,
          height: effectiveRadius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bgColor,
            border: showBorder
                ? Border.all(
                    color: borderColor ?? AppTheme.jeapPurple,
                    width: 2,
                  )
                : null,
          ),
          child: avatarContent,
        );

        if (badge != null) {
          root = Stack(
            clipBehavior: Clip.none,
            children: [
              root,
              Positioned(
                right: 0,
                bottom: 0,
                child: badge!,
              ),
            ],
          );
        }

        if (onTap != null) {
          return InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(effectiveRadius),
            child: root,
          );
        }

        return root;
      },
    );
  }

  Widget _buildFallback(double r, Color bg) {
    return Container(
      width: r * 2,
      height: r * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          color: AppTheme.jeapPurple,
          fontSize: r * 0.75,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
