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
    return LayoutBuilder(
      builder: (context, constraints) {
        final layoutWidth = _finiteDimension(width) ??
            (constraints.hasBoundedWidth ? constraints.maxWidth : null);
        final layoutHeight = _finiteDimension(height) ??
            (constraints.hasBoundedHeight ? constraints.maxHeight : null);
        final image = _buildImage(
          context,
          layoutWidth: layoutWidth,
          layoutHeight: layoutHeight,
        );
        if (borderRadius == null) {
          return image;
        }

        return ClipRRect(borderRadius: borderRadius!, child: image);
      },
    );
  }

  double? _finiteDimension(double? value) {
    return value != null && value.isFinite && value > 0 ? value : null;
  }

  Widget _buildImage(
    BuildContext context, {
    required double? layoutWidth,
    required double? layoutHeight,
  }) {
    final path = imagePath.trim();
    // Android rejects cleartext transport and remote menu artwork should never
    // downgrade to an unencrypted connection.
    final isRemote = path.startsWith('https://');
    final isBlockedRemote = path.startsWith('http://');
    final colors = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    final fallback = Container(
      width: width,
      height: height,
      color: appColors.sunkenSurface,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported_outlined,
        color: colors.onSurfaceVariant,
        semanticLabel: '$semanticLabel unavailable',
      ),
    );
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final targetWidth = layoutWidth != null
        ? (layoutWidth * pixelRatio).round().clamp(1, 1600).toInt()
        : null;
    final targetHeight = layoutHeight != null
        ? (layoutHeight * pixelRatio).round().clamp(1, 1600).toInt()
        : null;

    if (path.isEmpty || isBlockedRemote) {
      return fallback;
    }

    if (isRemote) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: targetWidth,
        cacheHeight: targetHeight,
        semanticLabel: semanticLabel,
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => fallback,
        loadingBuilder: (context, child, progress) {
          if (progress == null) {
            return child;
          }
          return Container(
            width: width,
            height: height,
            color: appColors.sunkenSurface,
            alignment: Alignment.center,
            child: Semantics(
              label: 'Loading $semanticLabel',
              child: const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
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
      cacheHeight: targetHeight,
      semanticLabel: semanticLabel,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}
