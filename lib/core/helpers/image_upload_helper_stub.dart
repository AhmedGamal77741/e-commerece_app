import 'dart:typed_data';

/// Stub function for non-web platforms.
Future<Uint8List> convertHeicWeb(Uint8List bytes) async {
  throw UnsupportedError('HEIC web conversion is only available on Web platform.');
}
