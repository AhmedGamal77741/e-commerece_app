import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

@JS('convertHeicToJpegWeb')
external JSPromise<JSUint8Array> convertHeicToJpegWebJS(JSUint8Array bytes);

/// Web-specific implementation invoking heic2any via JS Interop.
Future<Uint8List> convertHeicWeb(Uint8List bytes) async {
  try {
    final jsBytes = bytes.toJS;
    final promise = convertHeicToJpegWebJS(jsBytes);
    final resultJsArray = await promise.toDart;
    return resultJsArray.toDart;
  } catch (e) {
    throw Exception('HEIC 이미지 변환 실패 (Web): $e');
  }
}
