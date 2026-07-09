// ignore_for_file: non_constant_identifier_names

import 'dart:core';
import 'package:cloud_firestore/cloud_firestore.dart';

double toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

class PricePoint {
  int quantity;
  double price;
  bool? isMax;

  PricePoint({required this.quantity, required this.price, this.isMax});

  Map<String, dynamic> toMap() {
    return {
      'quantity': quantity,
      'price': price,
      if (isMax != null) 'isMax': isMax,
    };
  }

  factory PricePoint.fromMap(Map<String, dynamic> map) {
    return PricePoint(
      quantity: map['quantity'] ?? 1,
      price: toDouble(map['price']),
      isMax: map['isMax'] as bool?,
    );
  }
}

class Product {
  final String product_id;
  final String productName;
  final String sellerName;
  final String instructions;
  final String description;
  final String category;
  final List<String> categoryList;
  final int stock;
  final double price;
  final double supplyPrice;
  double? deliveryPrice;
  double? marginRate;
  double? shippingFee;
  double? estimatedSettlement;
  String? estimatedSettlementDate;
  final int baselineTime;
  final List<PricePoint> pricePoints;
  final bool freeShipping;
  final String meridiem;
  final String? imgUrl;
  final List<String?> imgUrls;
  final String? deliveryManagerId;
  final Map<String, dynamic>? address;
  final String? arrivalDate;
  final Timestamp? createdAt;
  final String memo;
  final List<String> favBy;

  // Fields synchronized from product_model_2.dart
  final String taxType;
  final String? shippingMethod;
  final double returnDeliveryPrice;
  final double freeShippingThreshold;
  final bool noFreeShipping;
  final int maxPackagingQuantity;
  final bool isSingleQuantity;
  final int deliveryMinDays;
  final int deliveryMaxDays;

  // Getter for backwards compatibility with productId
  String get productId => product_id;

  Product({
    required this.product_id,
    required this.productName,
    required this.sellerName,
    required this.category,
    required this.categoryList,
    required this.freeShipping,
    required this.instructions,
    required this.stock,
    required this.price,
    required this.supplyPrice,
    required this.description,
    this.deliveryPrice,
    this.marginRate,
    this.shippingFee,
    this.estimatedSettlement,
    this.estimatedSettlementDate,
    required this.baselineTime,
    required this.meridiem,
    required this.imgUrl,
    required this.imgUrls,
    required this.pricePoints,
    required this.deliveryManagerId,
    required this.address,
    this.arrivalDate,
    this.createdAt,
    required this.memo,
    required this.favBy,
    this.taxType = '과세',
    this.shippingMethod = '택배배송',
    this.returnDeliveryPrice = 5000.0,
    this.freeShippingThreshold = 20000.0,
    this.noFreeShipping = false,
    this.maxPackagingQuantity = 50,
    this.isSingleQuantity = false,
    this.deliveryMinDays = 1,
    this.deliveryMaxDays = 3,
  });

  factory Product.empty() {
    return Product(
      product_id: '',
      productName: '',
      sellerName: '',
      instructions: '',
      description: '',
      stock: 0,
      supplyPrice: 0.0,
      price: 0.0,
      baselineTime: 0,
      meridiem: 'AM',
      imgUrl: '',
      imgUrls: [],
      category: '',
      categoryList: [],
      pricePoints: [PricePoint(quantity: 1, price: 0)],
      freeShipping: false,
      deliveryManagerId: '',
      deliveryPrice: 0.0,
      marginRate: 0.0,
      shippingFee: 0.0,
      estimatedSettlement: 0.0,
      estimatedSettlementDate: '',
      address: {},
      arrivalDate: '',
      createdAt: Timestamp.now(),
      memo: '',
      favBy: const [],
      taxType: '과세',
      shippingMethod: '택배배송',
      returnDeliveryPrice: 5000.0,
      freeShippingThreshold: 20000.0,
      noFreeShipping: false,
      maxPackagingQuantity: 50,
      isSingleQuantity: false,
      deliveryMinDays: 1,
      deliveryMaxDays: 3,
    );
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    final rawPricePoints = map['pricePoints'] as List?;
    final parsedPricePoints =
        rawPricePoints
            ?.map(
              (pp) => PricePoint.fromMap(Map<String, dynamic>.from(pp as Map)),
            )
            .toList() ??
        [];
    final firstPrice =
        parsedPricePoints.isNotEmpty
            ? parsedPricePoints[0].price
            : toDouble(map['price']);

    return Product(
      product_id: map['product_id'] ?? '',
      productName: map['productName'] ?? '',
      instructions: map['instructions'] ?? '',
      description: map['description'] ?? map['storageInfo'] ?? '',
      stock: map['stock'] ?? 0,
      supplyPrice: toDouble(map['supplyPrice']),
      price: firstPrice,
      baselineTime: map['baselineTime'] ?? 0,
      meridiem: map['meridiem'] ?? 'AM',
      imgUrl: map['imgUrl'],
      imgUrls: List<String?>.from(map['imgUrls'] ?? []),
      sellerName: map['sellerName'] ?? '',
      category: map['category'] ?? '',
      categoryList: List<String>.from(map['categoryList'] ?? []),
      pricePoints: parsedPricePoints,
      freeShipping: map['freeShipping'] ?? false,
      deliveryManagerId: map['deliveryManagerId'] ?? '',
      deliveryPrice: toDouble(map['deliveryPrice']),
      marginRate: toDouble(map['marginRate']),
      shippingFee: toDouble(map['shippingFee']),
      estimatedSettlement: toDouble(map['estimatedSettlement']),
      estimatedSettlementDate: map['estimatedSettlementDate'] ?? '',
      address: map['address'] as Map<String, dynamic>?,
      arrivalDate: map['arrivalDate'],
      createdAt: map['createdAt'],
      memo: map['memo'] ?? '',
      favBy: List<String>.from(map['favBy'] ?? []),
      taxType: map['taxType'] ?? '과세',
      shippingMethod: map['shippingMethod'] as String? ??
          (map['address'] != null ? '지역배송' : '택배배송'),
      returnDeliveryPrice: toDouble(map['returnDeliveryPrice'] ?? 5000.0),
      freeShippingThreshold: toDouble(map['freeShippingThreshold'] ?? 20000.0),
      noFreeShipping: map['noFreeShipping'] ?? false,
      maxPackagingQuantity: map['maxPackagingQuantity'] ?? 50,
      isSingleQuantity: map['isSingleQuantity'] ?? false,
      deliveryMinDays: map['deliveryMinDays'] ?? 1,
      deliveryMaxDays: map['deliveryMaxDays'] ?? 3,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'product_id': product_id,
      'productName': productName,
      'name': productName,
      'instructions': instructions,
      'description': description,
      'stock': stock,
      'price': price,
      'supplyPrice': supplyPrice,
      'deliveryPrice': deliveryPrice,
      'marginRate': marginRate,
      'shippingFee': shippingFee,
      'estimatedSettlement': estimatedSettlement,
      'estimatedSettlementDate': estimatedSettlementDate,
      'baselineTime': baselineTime,
      'meridiem': meridiem,
      'imgUrl': imgUrl,
      'imgUrls': imgUrls,
      'sellerName': sellerName,
      'category': category,
      'categoryList': categoryList,
      'freeShipping': freeShipping,
      'pricePoints': pricePoints.map((pp) => pp.toMap()).toList(),
      'deliveryManagerId': deliveryManagerId,
      'address': address,
      'arrivalDate': arrivalDate,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'memo': memo,
      'favBy': favBy,
      'taxType': taxType,
      'shippingMethod': shippingMethod,
      'returnDeliveryPrice': returnDeliveryPrice,
      'freeShippingThreshold': freeShippingThreshold,
      'noFreeShipping': noFreeShipping,
      'maxPackagingQuantity': maxPackagingQuantity,
      'isSingleQuantity': isSingleQuantity,
      'deliveryMinDays': deliveryMinDays,
      'deliveryMaxDays': deliveryMaxDays,
    };
  }

  bool isProductDeliverableToUser({
    required Map<String, dynamic> userKakaoAddress, // The address map from Kakao API
    required List<String> includedSigungu,          // From product.address['includedSigungu']
    required List<String> excludedEupmyeondong,      // From product.address['excludedEupmyeondong']
  }) {
    // Extract user region components (supporting both flat and nested addressMap structure)
    final String r1 = userKakaoAddress['region_1depth_name'] as String? ??
        userKakaoAddress['road_address']?['region_1depth_name'] as String? ??
        userKakaoAddress['address']?['region_1depth_name'] as String? ??
        '';
    final String r2 = userKakaoAddress['region_2depth_name'] as String? ??
        userKakaoAddress['road_address']?['region_2depth_name'] as String? ??
        userKakaoAddress['address']?['region_2depth_name'] as String? ??
        '';
    final String r3 = userKakaoAddress['region_3depth_name'] as String? ??
        userKakaoAddress['road_address']?['region_3depth_name'] as String? ??
        userKakaoAddress['address']?['region_3depth_name'] as String? ??
        '';

    // 1. Construct user's local Sigungu matching key (inclusion check)
    final String userSigungu = r2.isNotEmpty ? '$r1 $r2' : r1;

    // 2. Check if the user is in an included city/district
    // Matches "경남 김해시" or "서울"
    final bool isIncluded = includedSigungu.any((area) => 
      userSigungu.contains(area) || area.contains(userSigungu)
    );
    if (!isIncluded) return false;

    // 3. Construct user's local Eupmyeondong matching key (exclusion check)
    // E.g., "경남 김해시 삼계동" or "서울 삼계동"
    final String userEupmyeondong = r2.isNotEmpty ? '$r1 $r2 $r3' : '$r1 $r3';

    // 4. Check if the user is in an excluded town/neighborhood
    final bool isExcluded = excludedEupmyeondong.any((exArea) => 
      userEupmyeondong.contains(exArea) || exArea.contains(userEupmyeondong)
    );

    return !isExcluded;
  }

  bool isDeliverableTo(Map<String, dynamic>? userKakaoAddress) {
    if (userKakaoAddress == null || userKakaoAddress.isEmpty) return false;

    // 1. If shippingMethod is 택배배송, it's deliverable to any user/address
    if (shippingMethod == '택배배송') {
      return true;
    }

    // 2. For 지역배송, we filter by address
    final List<dynamic> includedSigunguRaw = address?['includedSigungu'] ?? [];
    final List<String> includedSigungu = includedSigunguRaw.map((e) => e.toString()).toList();

    final List<dynamic> excludedEupmyeondongRaw = address?['excludedEupmyeondong'] ?? [];
    final List<String> excludedEupmyeondong = excludedEupmyeondongRaw.map((e) => e.toString()).toList();

    return isProductDeliverableToUser(
      userKakaoAddress: userKakaoAddress,
      includedSigungu: includedSigungu,
      excludedEupmyeondong: excludedEupmyeondong,
    );
  }
}
