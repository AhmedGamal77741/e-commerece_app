import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/core/providers/firebase_providers.dart';
import 'package:ecommerece_app/core/models/product_model.dart';
import 'package:ecommerece_app/features/shop/data/shop_repository.dart';
import 'package:ecommerece_app/features/cart/domain/cart_controller.dart';
import 'package:ecommerece_app/features/chat/domain/chat_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final shopControllerProvider = AsyncNotifierProvider<ShopController, void>(() {
  return ShopController();
});

final categoriesStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final repository = ref.watch(shopRepositoryProvider);
  return repository.categoriesStream().map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'] ?? 'Unknown',
      };
    }).toList();
  });
});

final categoryProductsStreamProvider = StreamProvider.family<List<Product>, String>((ref, categoryId) {
  final repository = ref.watch(shopRepositoryProvider);
  return repository.productsByCategoryStream(categoryId).map((snapshot) {
    return snapshot.docs.map((doc) => Product.fromMap(doc.data())).toList();
  });
});

final userDefaultAddressStreamProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(null);

  final repository = ref.watch(shopRepositoryProvider);
  return repository.userStream(user.uid).asyncMap((userDoc) async {
    if (!userDoc.exists) return null;
    final defaultAddressId = userDoc.data()?['defaultAddressId'] as String?;
    if (defaultAddressId == null || defaultAddressId.isEmpty) return null;

    final addressDoc = await repository.getAddress(user.uid, defaultAddressId);
        
    if (!addressDoc.exists) return null;
    return addressDoc.data();
  });
});

class ShopController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // nothing to build
  }
  
  Future<QuerySnapshot<Map<String, dynamic>>> getAllProducts() {
    return ref.read(shopRepositoryProvider).getAllProducts();
  }

  Future<void> addToCart({
    required String productId,
    required String deliveryManagerId,
    required int pricePointIndex,
    required String productName,
  }) async {
    return ref.read(cartControllerProvider).addToCart(
      productId: productId,
      deliveryManagerId: deliveryManagerId,
      pricePointIndex: pricePointIndex,
      productName: productName,
    );
  }

  Future<int?> getValidatedStock(String productId, int requestedQty) async {
    return ref.read(cartControllerProvider).getValidatedStock(productId, requestedQty);
  }

  Future<int> getCartItemQuantity(String productId) async {
    return ref.read(cartControllerProvider).getCartItemQuantity(productId);
  }

  Future<String?> processBuyNow({
    required Product product,
    required PricePoint pricePoint,
    required int pricePointIndex,
    required bool isSub,
  }) async {
    return ref.read(cartControllerProvider).processBuyNow(
      product: product,
      pricePoint: pricePoint,
      pricePointIndex: pricePointIndex,
      isSub: isSub,
    );
  }

  Future<void> removeFavItemByProductId(String productId) async {
    return ref.read(cartControllerProvider).removeFavItemByProductId(productId);
  }

  Future<void> addFavItem(String productId) async {
    return ref.read(cartControllerProvider).addFavItem(productId);
  }

  Future<List<dynamic>> createDirectChatRoomWithSeller(String sellerId) async {
    return ref.read(chatControllerProvider).createDirectChatRoomWithSeller(sellerId);
  }
}
