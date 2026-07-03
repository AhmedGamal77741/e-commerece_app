import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final checkoutRepositoryProvider = Provider<CheckoutRepository>((ref) {
  return CheckoutRepository();
});

class CheckoutRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getCachedUserValues(String uid) async {
    final doc = await _firestore.collection('usercached_values').doc(uid).get();
    return doc.data();
  }

  Future<void> saveCachedUserValues(String uid, Map<String, dynamic> data) async {
    await _firestore
        .collection('usercached_values')
        .doc(uid)
        .set(data, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getPendingBuynow(String uid, String paymentId) async {
    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('pending_buynow')
        .doc(paymentId)
        .get();
    return doc.data();
  }

  Future<void> patchPendingBuynow(String uid, String paymentId, Map<String, dynamic> data) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('pending_buynow')
        .doc(paymentId)
        .set(data, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getUserDefaultAddress(String uid) async {
    final userSnap = await _firestore.collection('users').doc(uid).get();
    if (!userSnap.exists) return null;

    final userData = userSnap.data() as Map<String, dynamic>;
    final defaultAddressId = userData['defaultAddressId'] as String?;
    if (defaultAddressId == null || defaultAddressId.isEmpty) return null;

    final addrSnap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('addresses')
        .doc(defaultAddressId)
        .get();
    if (!addrSnap.exists) return null;
    
    final addrData = addrSnap.data()!;
    addrData['id'] = addrData['id'] ?? defaultAddressId;
    return addrData;
  }

  String generateOrderId() {
    return _firestore.collection('orders').doc().id;
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getUserCartStream(String uid) {
    return _firestore.collection('users').doc(uid).collection('cart').snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getProductFuture(String productId) {
    return _firestore.collection('products').doc(productId).get();
  }

  Future<void> processCheckoutTransaction({
    required String uid,
    required String paymentId,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> orderData,
    required bool isCartCheckout,
  }) async {
    List<DocumentReference> cartRefs = [];
    if (isCartCheckout) {
      final cartSnap = await _firestore.collection('users').doc(uid).collection('cart').get();
      if (cartSnap.docs.isEmpty) throw Exception('Cart is empty.');
      cartRefs = cartSnap.docs.map((d) => d.reference).toList();
    } else {
      cartRefs.add(_firestore.collection('users').doc(uid).collection('pending_buynow').doc(paymentId));
    }

    await _firestore.runTransaction((transaction) async {
      // 1. Read Product Stock and Live Price for all items
      List<DocumentSnapshot> productSnaps = [];
      for (final item in items) {
        final productId = item['product_id'] as String;
        productSnaps.add(await transaction.get(_firestore.collection('products').doc(productId)));
      }

      final userSnap = await transaction.get(_firestore.collection('users').doc(uid));
      final isSubed = userSnap.data()?['isSub'] ?? false;

      // 2. Validate
      Map<String, int> productRequestedQuantities = {};
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        final prodSnap = productSnaps[i];
        if (!prodSnap.exists) {
          throw Exception('Product ${item['productName'] ?? item['product_id']} not found.');
        }

        final prodData = prodSnap.data() as Map<String, dynamic>;
        final pricePointIndex = item['pricePointIndex'] as int;
        final pricePoints = prodData['pricePoints'] as List<dynamic>? ?? [];
        if (pricePointIndex >= pricePoints.length) {
          throw Exception('Invalid price point for ${prodData['productName']}');
        }

        final pp = Map<String, dynamic>.from(pricePoints[pricePointIndex] as Map);
        final requestedQuantity = (item['quantity'] as num?)?.toInt() ?? (pp['quantity'] as num?)?.toInt() ?? 1;
        item['quantity'] = requestedQuantity; // Inject for order saving

        final productId = item['product_id'] as String;
        productRequestedQuantities[productId] = (productRequestedQuantities[productId] ?? 0) + requestedQuantity;

        num computedPrice = pp['price'] ?? 0;
        if (!isSubed) {
          computedPrice = (computedPrice / 0.8).round();
        }
        final livePrice = computedPrice.round();
        
        final cachedPrice = (item['price'] as num?)?.toInt();
        if (cachedPrice != null && livePrice != cachedPrice) {
          throw Exception('Price changed for ${prodData['productName']}. Please refresh the cart. (가격 변동)');
        }
        item['price'] = livePrice; // Inject for order saving
      }

      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        final productId = item['product_id'] as String;
        final prodSnap = productSnaps[i];
        final prodData = prodSnap.data() as Map<String, dynamic>;
        final liveStock = (prodData['stock'] as num?)?.toInt() ?? 0;
        final totalRequested = productRequestedQuantities[productId]!;

        if (liveStock < totalRequested) {
          throw Exception('Out of stock: ${prodData['productName']} (재고 부족)');
        }
      }

      // 3. Execute
      Set<String> updatedProducts = {};
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        final productId = item['product_id'] as String;
        final prodSnap = productSnaps[i];
        
        if (!updatedProducts.contains(productId)) {
          final totalRequested = productRequestedQuantities[productId]!;
          transaction.update(prodSnap.reference, {
            'stock': FieldValue.increment(-totalRequested)
          });
          updatedProducts.add(productId);
        }
      }

      final orderRef = _firestore.collection('orders').doc(paymentId);
      transaction.set(orderRef, {
        'order_id': paymentId,
        'user_id': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'items': items,
        ...orderData,
      });

      for (final ref in cartRefs) {
        transaction.delete(ref);
      }
    });
  }
}
