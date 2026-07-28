import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';

class OptimizedUploadImage {
  const OptimizedUploadImage({
    required this.bytes,
    required this.fileName,
    required this.contentType,
  });

  final Uint8List bytes;
  final String fileName;
  final String contentType;
}

abstract final class UploadImageOptimizer {
  static const _compressionThreshold = 600 * 1024;

  static Future<OptimizedUploadImage> optimize({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {
    final original = OptimizedUploadImage(
      bytes: bytes,
      fileName: fileName,
      contentType: contentType,
    );
    if (bytes.length < _compressionThreshold) return original;

    try {
      final compressed = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 1600,
        minHeight: 1600,
        quality: 82,
        format: CompressFormat.webp,
        keepExif: false,
      );
      if (compressed.isEmpty || compressed.length >= bytes.length) {
        return original;
      }

      final baseName = fileName.replaceFirst(RegExp(r'\.[^.]+$'), '');
      return OptimizedUploadImage(
        bytes: Uint8List.fromList(compressed),
        fileName: '$baseName.webp',
        contentType: 'image/webp',
      );
    } catch (_) {
      // Uploading the validated original is safer than blocking an order admin.
      return original;
    }
  }
}
