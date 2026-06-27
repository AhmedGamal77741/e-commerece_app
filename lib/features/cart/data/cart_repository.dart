import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/core/models/product_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepository(FirebaseFirestore.instance);
});

class CartRepository {
  final FirebaseFirestore _firestore;

  CartRepository(this._firestore);

  Future<void> addProductToCart({
    required String userId,
    required String productId,
    required String deliveryManagerId,
    required int pricePointIndex,
    required String productName,
  }) async {
    final cartRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('cart');

    await cartRef.add({
      'cart_id': cartRef.doc().id,
      'product_id': productId,
      'pricePointIndex': pricePointIndex,
      'added_at': FieldValue.serverTimestamp(),
      'deliveryManagerId': deliveryManagerId,
      'productName': productName,
    });
  }

  Future<void> deleteCartItem(String userId, String cartId) async {
    if (userId.isNotEmpty && cartId.isNotEmpty) {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc(cartId)
          .delete();
    }
  }

  Future<void> deleteFavItem(String userId, String favId) async {
    if (userId.isNotEmpty && favId.isNotEmpty) {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(favId)
          .delete();
      // Note: This doesn't remove from the product's favBy array because we don't have productId here easily without a read.
      // But we will use removeFavItemByProductId mostly from the UI.
    }
  }

  Future<void> addFavItem({
    required String userId,
    required String productId,
  }) async {
    final favoritesRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites');
    final productRef = _firestore.collection('products').doc(productId);

    final newDocRef = favoritesRef.doc();
    await newDocRef.set({'favorite_id': newDocRef.id, 'product_id': productId});

    await productRef.update({
      'favBy': FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> removeFavItemByProductId({
    required String userId,
    required String productId,
  }) async {
    final favoritesRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites');
    final productRef = _firestore.collection('products').doc(productId);

    final querySnapshot =
        await favoritesRef.where('product_id', isEqualTo: productId).get();

    final batch = _firestore.batch();
    for (var doc in querySnapshot.docs) {
      batch.delete(doc.reference);
    }
    batch.update(productRef, {
      'favBy': FieldValue.arrayRemove([userId]),
    });

    await batch.commit();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> userCartStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .orderBy('added_at', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> userFavoritesStream(
    String userId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> productStream(
    String productId,
  ) {
    return _firestore.collection('products').doc(productId).snapshots();
  }

  Future<int?> getValidatedStock(String productId, int requestedQty) async {
    final productSnapshot =
        await _firestore.collection('products').doc(productId).get();
    final currentStock = productSnapshot.data()?['stock'] ?? 0;
    if (requestedQty > currentStock) {
      return null;
    }
    return currentStock;
  }

  Future<int> getCartItemQuantity(String userId, String productId) async {
    final cartQuery =
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('cart')
            .where('product_id', isEqualTo: productId)
            .get();

    int cartTotalQuantity = 0;
    for (var doc in cartQuery.docs) {
      cartTotalQuantity += (doc.data()['quantity'] ?? 0) as int;
    }
    return cartTotalQuantity;
  }

  Future<String> processBuyNow({
    required String userId,
    required Product product,
    required PricePoint pricePoint,
    required int pricePointIndex,
    required int finalPrice,
  }) async {
    final paymentId = _firestore.collection('orders').doc().id;
    final pendingColl = _firestore
        .collection('users')
        .doc(userId)
        .collection('pending_buynow');

    final batch = _firestore.batch();

    final existing = await pendingColl.get();
    for (final doc in existing.docs) {
      batch.delete(doc.reference);
    }

    batch.set(pendingColl.doc(paymentId), {
      'product_id': product.product_id,
      'product_name': product.productName,
      'imgUrl': product.imgUrl ?? '',
      'deliveryManagerId': product.deliveryManagerId,
      'price': finalPrice,
      'quantity': pricePoint.quantity,
      'pricePointIndex': pricePointIndex,
      'paymentId': paymentId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    return paymentId;
  }

  Future<void> refreshCartPrices(String uid) async {
    final userSnapshot = await _firestore.collection('users').doc(uid).get();
    final isSubed = userSnapshot.data()?['isSub'] ?? false;
    final cartSnapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('cart')
        .get();
    
    for (final cartDoc in cartSnapshot.docs) {
      final cartData = cartDoc.data();
      final productId = cartData['product_id'] as String?;
      final pricePointIndex = cartData['pricePointIndex'] is int
          ? cartData['pricePointIndex'] as int
          : int.tryParse('${cartData['pricePointIndex']}') ?? 0;
      
      if (productId == null) continue;
      
      final productRef = _firestore.collection('products').doc(productId);
      final productSnap = await productRef.get();
      if (!productSnap.exists) continue;
      
      final prodData = productSnap.data()!;
      final prod = Product.fromMap(prodData);
      
      num computedPrice;
      try {
        final pp = prod.pricePoints[pricePointIndex];
        if (isSubed) {
          computedPrice = pp.price;
        } else {
          computedPrice = (pp.price / 0.8).round();
        }
      } catch (e) {
        final fallback = prodData['price'] ?? cartData['price'] ?? 0;
        computedPrice = fallback is num ? fallback : num.parse('$fallback');
      }
      
      final intPrice = computedPrice is double ? computedPrice.round() : computedPrice.toInt();
      await cartDoc.reference.update({'price': intPrice});
    }
  }
}
