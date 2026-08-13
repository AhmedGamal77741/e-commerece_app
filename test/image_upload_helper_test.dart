import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerece_app/core/helpers/image_upload_helper.dart';

void main() {
  group('ImageUploadHelper Tests', () {
    test('detects HEIC by filename extension', () {
      final dummyBytes = Uint8List.fromList([0, 1, 2, 3]);
      expect(ImageUploadHelper.isHeicFormat(dummyBytes, 'photo.heic'), isTrue);
      expect(ImageUploadHelper.isHeicFormat(dummyBytes, 'PHOTO.HEIF'), isTrue);
      expect(ImageUploadHelper.isHeicFormat(dummyBytes, 'image.jpg'), isFalse);
      expect(ImageUploadHelper.isHeicFormat(dummyBytes, 'graphic.png'), isFalse);
    });

    test('detects HEIC by ftyp magic bytes', () {
      // Constructs valid ftyp heic magic bytes: [0..3 length], 'ftyp', 'heic'
      final heicMagicBytes = Uint8List.fromList([
        0x00, 0x00, 0x00, 0x18,
        0x66, 0x74, 0x79, 0x70, // 'ftyp'
        0x68, 0x65, 0x69, 0x63, // 'heic'
      ]);
      expect(ImageUploadHelper.isHeicFormat(heicMagicBytes, 'unknown_file'), isTrue);
    });

    test('lookupMimeType returns correct content types', () {
      expect(ImageUploadHelper.lookupMimeType('.png'), equals('image/png'));
      expect(ImageUploadHelper.lookupMimeType('.webp'), equals('image/webp'));
      expect(ImageUploadHelper.lookupMimeType('.heic'), equals('image/heic'));
      expect(ImageUploadHelper.lookupMimeType('.jpg'), equals('image/jpeg'));
    });
  });
}
