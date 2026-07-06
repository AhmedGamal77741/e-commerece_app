import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository(FirebaseFirestore.instance);
});

class ReviewRepository {
  final FirebaseFirestore _firestore;

  ReviewRepository(this._firestore);

  Stream<QuerySnapshot> getUserOrdersStream(String userId) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('orderDate', descending: true)
        .snapshots();
  }

  Future<Map<String, dynamic>?> getProduct(String productId) async {
    final doc = await _firestore.collection('products').doc(productId).get();
    return doc.exists ? doc.data() : null;
  }

  Future<Map<String, dynamic>?> getOrder(String orderId) async {
    final doc = await _firestore.collection('orders').doc(orderId).get();
    return doc.exists ? doc.data() : null;
  }

  /// Returns a real-time stream of a single order document's data.
  Stream<Map<String, dynamic>?> getOrderStream(String orderId) {
    return _firestore
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .map((doc) => doc.exists ? doc.data() : null);
  }

  Future<void> submitRequest(String userId, String orderId, Map<String, dynamic> requestData) async {
    final type = requestData['type'] == 'exchange' ? 'exchanges' : 'refunds';
    final docRef = _firestore.collection(type).doc();
    
    final payload = {
      ...requestData,
      'requestId': docRef.id,
      'userId': userId,
      'orderId': orderId,
      'createdAt': DateTime.now().toIso8601String(),
    };
    
    // Find the settlement document to pause it (so seller doesn't get automatically paid while disputed)
    final settlementQuery = await _firestore.collection('order_settlement').where('orderId', isEqualTo: orderId).get();
    final settlementDocs = settlementQuery.docs;

    await _firestore.runTransaction((transaction) async {
      transaction.set(docRef, payload);
      transaction.update(_firestore.collection('orders').doc(orderId), {'isRequested': true});
      for (var doc in settlementDocs) {
        transaction.update(doc.reference, {'status': 'disputed'});
      }
    });
  }

  Future<void> submitReview(Map<String, dynamic> reviewData) async {
    await _firestore.collection('reviews').add(reviewData);
  }

  Future<Map<String, dynamic>> requestRefundFunction(String uid, String orderId) async {
    final callable = FirebaseFunctions.instance.httpsCallable('requestRefund');
    final result = await callable.call({
      'uid': uid,
      'orderId': orderId,
      'type': 'cancel',
    });
    return result.data as Map<String, dynamic>;
  }

  /// Returns `true` if the order has been dispatched based on the product's
  /// baseline shipping cutoff time and the order date.
  static bool isDispatched(Map<String, dynamic> product, String orderDate) {
    final now = DateTime.now();
    final orderTime = DateTime.parse(orderDate);
    int adjustedHour = product['baselineTime'] as int;
    final meridiem = (product['meridiem'] as String).toLowerCase();
    if (meridiem == 'pm' && adjustedHour < 12) {
      adjustedHour += 12;
    } else if (meridiem == 'am' && adjustedHour == 12) {
      adjustedHour = 0;
    }
    final cutoff = DateTime(
      orderTime.year,
      orderTime.month,
      orderTime.day,
      adjustedHour,
    );
    final nextDay = cutoff.add(const Duration(days: 1));
    if (orderTime.isBefore(cutoff) && now.isAfter(cutoff)) return true;
    if (orderTime.isAfter(cutoff) && now.isAfter(nextDay)) return true;
    return false;
  }
}
