import 'package:ecommerece_app/features/shop/data/product_entity.dart';

class Product {
  final String productId;
  final String sellerName;
  final String productName;
  final double price;
  final int stockAmount;
  final bool freeShipping;
  final DateTime baselineTime;
  final String meridiem;
  final String category;

  Product({
    required this.productId,
    required this.sellerName,
    required this.productName,
    required this.price,
    required this.stockAmount,
    required this.freeShipping,
    required this.baselineTime,
    required this.meridiem,
    required this.category,
  });

  static Product fromEntity(ProductEntity entity) {
    return Product(
      productId: entity.productId,
      sellerName: entity.sellerName,
      productName: entity.productName,
      price: entity.price,
      stockAmount: entity.stockAmount,
      freeShipping: entity.freeShipping,
      baselineTime: entity.baselineTime,
      meridiem: entity.meridiem,
      category: entity.category,
    );
  }

  @override
  String toString() {
    return 'Product: $productId, $sellerName, $productName, $price, $stockAmount, $freeShipping, $baselineTime, $meridiem, $category';
  }
}
