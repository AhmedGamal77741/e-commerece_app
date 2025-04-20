import 'package:cloud_firestore/cloud_firestore.dart';

class ProductEntity {
  final String productId;
  final String sellerName;
  final String productName;
  final double price;
  final int stockAmount;
  final bool freeShipping;
  final DateTime baselineTime;
  final String meridiem;
  final String category;

  ProductEntity({
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

  Map<String, Object?> toDocument() {
    return {
      'productId': productId,
      'sellerName': sellerName,
      'productName': productName,
      'price': price,
      'stockAmount': stockAmount,
      'freeShipping': freeShipping,
      'baselineTime': baselineTime,
      'meridiem': meridiem,
      'category': category,
    };
  }

  static ProductEntity fromDocument(Map<String, dynamic> doc) {
    return ProductEntity(
      productId: doc['productId'] as String,
      sellerName: doc['sellerName'] as String,
      productName: doc['productName'] as String,
      price: (doc['price'] as num).toDouble(),
      stockAmount: doc['stockAmount'] as int,
      freeShipping: doc['freeShipping'] as bool,
      baselineTime: (doc['baselineTime'] as Timestamp).toDate(),
      meridiem: doc['meridiem'] as String,
      category: doc['category'] as String,
    );
  }
}
