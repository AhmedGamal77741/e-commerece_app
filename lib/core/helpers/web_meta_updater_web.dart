import 'dart:js_interop';
import 'package:ecommerece_app/core/models/product_model.dart';

@JS('document.title')
external set _documentTitle(JSString title);

class WebMetaUpdater {
  static void updateProductMeta(Product product) {
    try {
      final title = '${product.productName} - 팽이초콜릿';
      _setDocumentTitle(title);
    } catch (_) {}
  }

  static void _setDocumentTitle(String title) {
    try {
      _documentTitle = title.toJS;
    } catch (_) {}
  }
}
