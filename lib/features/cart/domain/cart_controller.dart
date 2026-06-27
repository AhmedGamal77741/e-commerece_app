import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ecommerece_app/core/models/product_model.dart';
import 'package:ecommerece_app/features/cart/data/cart_repository.dart';
import 'package:ecommerece_app/features/auth/domain/auth_controller.dart';
import 'package:ecommerece_app/core/providers/firebase_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final cartControllerProvider = NotifierProvider<CartController, void>(() {
  return CartController();
});

final userCartStreamProvider = StreamProvider<List<QueryDocumentSnapshot<Map<String, dynamic>>>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value([]);
  }
  final repository = ref.watch(cartRepositoryProvider);
  return repository.userCartStream(user.uid).map((snapshot) => snapshot.docs);
});

final userFavoritesStreamProvider = StreamProvider<List<QueryDocumentSnapshot<Map<String, dynamic>>>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value([]);
  }
  final repository = ref.watch(cartRepositoryProvider);
  return repository.userFavoritesStream(user.uid).map((snapshot) => snapshot.docs);
});

final productStreamProvider = StreamProvider.family<Product?, String>((ref, productId) {
  final repository = ref.watch(cartRepositoryProvider);
  return repository.productStream(productId).map((snapshot) {
    if (!snapshot.exists || snapshot.data() == null) return null;
    return Product.fromMap(snapshot.data()!);
  });
});

final cartTotalProvider = Provider<int>((ref) {
  final cartDocsAsync = ref.watch(userCartStreamProvider);
  final isSub = ref.watch(isSubscribedProvider).value ?? false;

  final cartDocs = cartDocsAsync.value;
  if (cartDocs == null || cartDocs.isEmpty) {
    return 0;
  }

  int total = 0;
  for (final cartDoc in cartDocs) {
    final cartData = cartDoc.data();
    final productId = cartData['product_id'] as String?;
    final pricePointIndex = (cartData['pricePointIndex'] as int?) ?? 0;

    if (productId != null) {
      final productAsync = ref.watch(productStreamProvider(productId));
      final product = productAsync.value;
      if (product != null && pricePointIndex < product.pricePoints.length) {
        final pricePoint = product.pricePoints[pricePointIndex];
        double price = pricePoint.price.toDouble();
        if (!isSub) {
          price = price / 0.8;
        }
        total += price.round();
      }
    }
  }

  return total;
});

class CartController extends Notifier<void> {
  @override
  void build() {}

  Future<void> addToCart({
    required String productId,
    required String deliveryManagerId,
    required int pricePointIndex,
    required String productName,
  }) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    
    await ref.read(cartRepositoryProvider).addProductToCart(
      userId: user.uid,
      productId: productId,
      deliveryManagerId: deliveryManagerId,
      pricePointIndex: pricePointIndex,
      productName: productName,
    );
  }

  Future<void> removeCartItem(String cartId) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    await ref.read(cartRepositoryProvider).deleteCartItem(user.uid, cartId);
  }

  Future<void> removeFavItem(String favId) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    await ref.read(cartRepositoryProvider).deleteFavItem(user.uid, favId);
  }

  Future<void> addFavItem(String productId) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    await ref.read(cartRepositoryProvider).addFavItem(userId: user.uid, productId: productId);
  }

  Future<void> removeFavItemByProductId(String productId) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    await ref.read(cartRepositoryProvider).removeFavItemByProductId(userId: user.uid, productId: productId);
  }

  Future<int?> getValidatedStock(String productId, int requestedQty) async {
    return await ref.read(cartRepositoryProvider).getValidatedStock(productId, requestedQty);
  }

  Future<int> getCartItemQuantity(String productId) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return 0;
    return await ref.read(cartRepositoryProvider).getCartItemQuantity(user.uid, productId);
  }

  Future<String?> processBuyNow({
    required Product product,
    required PricePoint pricePoint,
    required int pricePointIndex,
    required bool isSub,
  }) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return null;

    final finalPrice = isSub ? pricePoint.price : (pricePoint.price / 0.8).round();

    return await ref.read(cartRepositoryProvider).processBuyNow(
      userId: user.uid,
      product: product,
      pricePoint: pricePoint,
      pricePointIndex: pricePointIndex,
      finalPrice: finalPrice,
    );
  }
}

Future<bool> isUserSubscribed() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;
  final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  final data = userDoc.data();
  if (data == null || data['isSub'] == null) return false;
  return data['isSub'] == true;
}
