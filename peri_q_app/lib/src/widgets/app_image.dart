import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.semanticLabel = 'Food image',
  });

  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final image = _buildImage(context);
    if (borderRadius == null) {
      return image;
    }

    return ClipRRect(borderRadius: borderRadius!, child: image);
  }

  Widget _buildImage(BuildContext context) {
    final path = imagePath.trim();
    final isRemote = path.startsWith('http://') || path.startsWith('https://');
    final fallback = Container(
      width: width,
      height: height,
      color: AppTheme.mutedSurface,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: AppTheme.ashGrey,
      ),
    );
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final targetWidth = width != null && width!.isFinite
        ? (width! * pixelRatio).round().clamp(1, 1200)
        : null;

    if (path.isEmpty) {
      return fallback;
    }

    if (isRemote) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: targetWidth,
        semanticLabel: semanticLabel,
        errorBuilder: (_, _, _) => fallback,
        loadingBuilder: (context, child, progress) {
          if (progress == null) {
            return child;
          }
          return Container(
            width: width,
            height: height,
            color: AppTheme.mutedSurface,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      );
    }

    return Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: targetWidth,
      semanticLabel: semanticLabel,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}
