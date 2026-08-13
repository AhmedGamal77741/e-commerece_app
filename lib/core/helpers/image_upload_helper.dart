import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import 'image_upload_helper_stub.dart'
    if (dart.library.js_interop) 'image_upload_helper_web.dart';

class PreparedImageData {
  final Uint8List bytes;
  final String extension;
  final String contentType;

  PreparedImageData({
    required this.bytes,
    required this.extension,
    required this.contentType,
  });
}

class ImageUploadHelper {
  /// Detects HEIC/HEIF magic bytes or extension.
  static bool isHeicFormat(Uint8List rawBytes, String filename) {
    final lowerName = filename.toLowerCase();
    if (lowerName.endsWith('.heic') || lowerName.endsWith('.heif')) {
      return true;
    }

    if (rawBytes.length >= 12) {
      try {
        final ftyp = String.fromCharCodes(rawBytes.sublist(4, 8));
        final brand = String.fromCharCodes(rawBytes.sublist(8, 12));
        if (ftyp == 'ftyp' &&
            (brand.startsWith('hei') ||
                brand.startsWith('mif1') ||
                brand.startsWith('msf1') ||
                brand.startsWith('hvc') ||
                brand.startsWith('hevc'))) {
          return true;
        }
      } catch (_) {}
    }

    return false;
  }

  /// Maps extension to MIME type.
  static String lookupMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.gif':
        return 'image/gif';
      case '.heic':
      case '.heif':
        return 'image/heic';
      case '.jpg':
      case '.jpeg':
      default:
        return 'image/jpeg';
    }
  }

  /// Prepares image bytes for upload with platform-aware HEIC conversion and JPEG compression.
  static Future<PreparedImageData> prepareImageForUpload({
    required Uint8List rawBytes,
    required String originalName,
    int minWidth = 1080,
    int minHeight = 1080,
    int quality = 82,
  }) async {
    final int dotIndex = originalName.lastIndexOf('.');
    final String originalExtension =
        dotIndex != -1 ? originalName.substring(dotIndex).toLowerCase() : '';
    final bool isHeic = isHeicFormat(rawBytes, originalName);

    Uint8List uploadBytes;
    String finalExtension = '.jpg';
    String contentType = 'image/jpeg';

    if (isHeic) {
      if (kIsWeb) {
        try {
          uploadBytes = await convertHeicWeb(rawBytes);
        } catch (e) {
          throw Exception('HEIC/HEIF 이미지 변환 실패: $e');
        }
      } else {
        try {
          final Uint8List compressed =
              await FlutterImageCompress.compressWithList(
            rawBytes,
            minWidth: minWidth,
            minHeight: minHeight,
            quality: quality,
            format: CompressFormat.jpeg,
          );
          uploadBytes = compressed;
        } catch (e) {
          throw Exception('Failed to compress/convert HEIC image to JPEG: $e');
        }
      }
    } else {
      try {
        final Uint8List compressed =
            await FlutterImageCompress.compressWithList(
          rawBytes,
          minWidth: minWidth,
          minHeight: minHeight,
          quality: quality,
          format: CompressFormat.jpeg,
        );
        uploadBytes = compressed;
      } catch (_) {
        uploadBytes = rawBytes;
        finalExtension = originalExtension.isEmpty ? '.jpg' : originalExtension;
        contentType = lookupMimeType(originalExtension);
      }
    }

    return PreparedImageData(
      bytes: uploadBytes,
      extension: finalExtension,
      contentType: contentType,
    );
  }

  /// Prepares image bytes for preview (converts HEIC/HEIF to JPEG if necessary).
  static Future<Uint8List> preparePreviewBytes(Uint8List rawBytes, String filename) async {
    if (isHeicFormat(rawBytes, filename)) {
      try {
        final prepared = await prepareImageForUpload(
          rawBytes: rawBytes,
          originalName: filename,
        );
        return prepared.bytes;
      } catch (e) {
        debugPrint('Error preparing HEIC preview bytes: $e');
      }
    }
    return rawBytes;
  }
}
