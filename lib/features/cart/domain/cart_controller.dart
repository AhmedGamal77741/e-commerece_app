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

    final int finalPrice = (isSub ? pricePoint.price : (pricePoint.price / 0.8)).round();

    return await ref.read(cartRepositoryProvider).processBuyNow(
      userId: user.uid,
      product: product,
      pricePoint: pricePoint,
      pricePointIndex: pricePointIndex,
      finalPrice: finalPrice,
    );
  }

  Future<void> validateStockAvailability() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) throw Exception('사용자 인증이 필요합니다.');

    final cartDocs = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .get();

    Map<String, int> requestedQuantities = {};
    
    for (final doc in cartDocs.docs) {
      final data = doc.data();
      final productId = data['product_id'] as String?;
      final pricePointIndex = data['pricePointIndex'] is int 
          ? data['pricePointIndex'] as int 
          : int.tryParse('${data['pricePointIndex']}') ?? 0;
      
      if (productId == null) continue;

      final productSnap = await FirebaseFirestore.instance.collection('products').doc(productId).get();
      if (!productSnap.exists) continue;
      
      final product = Product.fromMap(productSnap.data()!);
      int qty = 1;
      if (pricePointIndex >= 0 && pricePointIndex < product.pricePoints.length) {
        qty = product.pricePoints[pricePointIndex].quantity;
      }
      
      requestedQuantities[productId] = (requestedQuantities[productId] ?? 0) + qty;
    }

    for (final productId in requestedQuantities.keys) {
      final requestedQty = requestedQuantities[productId]!;
      final productSnap = await FirebaseFirestore.instance.collection('products').doc(productId).get();
      if (!productSnap.exists) continue;

      final data = productSnap.data()!;
      final currentStock = data['stock'] as int? ?? 0;
      final productName = data['productName'] as String? ?? '상품';
      
      if (requestedQty > currentStock) {
         throw Exception('재고 부족: $productName의 남은 재고가 $currentStock개입니다.');
      }
    }
  }

  Future<void> detectPriceChanges() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) throw Exception('사용자 인증이 필요합니다.');

    final isSub = await isUserSubscribed();
    
    final cartDocs = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .get();

    bool hasChanges = false;
    List<String> changedItems = [];

    for (final doc in cartDocs.docs) {
      final cartData = doc.data();
      final productId = cartData['product_id'] as String?;
      final pricePointIndex = cartData['pricePointIndex'] is int 
          ? cartData['pricePointIndex'] as int 
          : int.tryParse('${cartData['pricePointIndex']}') ?? 0;
      
      if (productId == null) continue;

      final productSnap = await FirebaseFirestore.instance.collection('products').doc(productId).get();
      if (!productSnap.exists) continue;

      final prodData = productSnap.data()!;
      final prod = Product.fromMap(prodData);

      num computedPrice;
      try {
        final pp = prod.pricePoints[pricePointIndex];
        if (isSub) {
          computedPrice = pp.price;
        } else {
          computedPrice = (pp.price / 0.8).round();
        }
      } catch (e) {
        continue;
      }
      
      final livePrice = computedPrice is double ? computedPrice.round() : computedPrice.toInt();
      final currentCartPrice = cartData['price'] as int?;

      if (currentCartPrice != null && currentCartPrice != livePrice) {
        hasChanges = true;
        if (!changedItems.contains(prod.productName)) {
          changedItems.add(prod.productName);
        }
      }
      
      if (currentCartPrice != livePrice) {
        await doc.reference.update({'price': livePrice});
      }
    }

    if (hasChanges) {
      final itemsStr = changedItems.join(', ');
      throw Exception('가격 변동 알림: $itemsStr의 가격이 변경되었습니다. 장바구니에서 최신 가격을 확인 후 다시 결제해주세요.');
    }
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
