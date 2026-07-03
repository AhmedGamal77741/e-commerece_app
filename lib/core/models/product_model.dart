// models/product_model.dart

import 'dart:core';

class PricePoint {
  int quantity;
  int price;

  PricePoint({required this.quantity, required this.price});

  Map<String, dynamic> toMap() {
    return {'quantity': quantity, 'price': price};
  }

  factory PricePoint.fromMap(Map<String, dynamic> map) {
    return PricePoint(
      quantity: (map['quantity'] as num).toInt(),
      price: (map['price'] as num).toInt(),
    );
  }
}

class Product {
  final String productId;
  final String productName;
  final String sellerName;
  final String instructions;
  final String category;
  final int stock;
  final int price;
  final int supplyPrice;
  int? deliveryPrice;
  double? marginRate;
  int? shippingFee;
  final int baselineTime;
  final List<PricePoint> pricePoints;
  final bool freeShipping;
  final String meridiem;
  final String? imgUrl;
  final List<String?> imgUrls;
  List<String> favBy = [];
  final String? deliveryManagerId;
  final Map<String, dynamic>? address;
  final String? arrivalDate;
  final String? description;

  Product({
    required this.productId,
    required this.productName,
    required this.sellerName,
    required this.category,
    required this.freeShipping,
    required this.instructions,
    required this.stock,
    required this.price,
    required this.baselineTime,
    required this.meridiem,
    required this.imgUrl,
    required this.imgUrls,
    required this.pricePoints,
    required this.favBy,
    required this.deliveryManagerId,
    required this.address,
    required this.supplyPrice,
    this.deliveryPrice,
    this.marginRate,
    this.shippingFee,
    this.arrivalDate,
    this.description,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    final rawPricePoints = map['pricePoints'] as List?;
    final List<PricePoint> parsedPricePoints = [];
    if (rawPricePoints != null) {
      for (final pp in rawPricePoints) {
        if (pp is Map) {
          parsedPricePoints.add(PricePoint.fromMap(Map<String, dynamic>.from(pp)));
        }
      }
    }

    final int calculatedPrice = parsedPricePoints.isNotEmpty 
        ? parsedPricePoints.first.price 
        : (map['price'] as num?)?.toInt() ?? 0;

    return Product(
      productId: map['product_id'] ?? '',
      productName: map['productName'] ?? '',
      instructions: map['instructions'] ?? '',
      stock: map['stock'] ?? 0,
      supplyPrice: map['supplyPrice'] ?? 0,
      price: calculatedPrice,
      baselineTime: map['baselineTime'] ?? 0,
      meridiem: map['meridiem'] ?? 'AM',
      imgUrl: map['imgUrl'],
      imgUrls: (map['imgUrls'] as List?)
              ?.map((e) => e?.toString())
              .toList() ??
          const [],
      sellerName: map['sellerName'] ?? '',
      category: map['category'] ?? '',
      pricePoints: parsedPricePoints,
      freeShipping: map['freeShipping'] ?? false,
      favBy: List<String>.from(map['favBy'] ?? []),
      deliveryManagerId: map['deliveryManagerId'] ?? '',
      deliveryPrice: map['deliveryPrice'] ?? 0,
      marginRate:
          map['marginRate'] != null
              ? (map['marginRate'] as num).toDouble()
              : null,
      shippingFee: map['shippingFee'] ?? 0,
      address: map['address'] != null
          ? Map<String, dynamic>.from(map['address'])
          : null,
      arrivalDate: map['arrivalDate'],
      description: map['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'productName': productName,
      'instructions': instructions,
      'stock': stock,
      'price': price,
      'supplyPrice': supplyPrice,
      'deliveryPrice': deliveryPrice,
      'marginRate': marginRate,
      'shippingFee': shippingFee,
      'baselineTime': baselineTime,
      'meridiem': meridiem,
      'imgUrl': imgUrl,
      'imgUrls': imgUrls,
      'sellerName': sellerName,
      'category': category,
      'freeShipping': freeShipping,
      'pricePoints': pricePoints.map((pp) => pp.toMap()).toList(),
      'favBy': favBy,
      'deliveryManagerId': deliveryManagerId,
      'address': address,
      'arrivalDate': arrivalDate,
      'description': description,
    };
  }
}
