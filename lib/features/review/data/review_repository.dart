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

  Future<void> submitExchangeRequest(String userId, String orderId, String reason) async {
    final docRef = _firestore.collection('exchanges').doc();
    final exchangeData = {
      'exchangeId': docRef.id,
      'userId': userId,
      'orderId': orderId,
      'reason': reason.trim(),
      'createdAt': DateTime.now().toIso8601String(),
    };
    
    await _firestore.runTransaction((transaction) async {
      transaction.set(docRef, exchangeData);
      transaction.update(_firestore.collection('orders').doc(orderId), {'isRequested': true});
    });
  }

  Future<void> submitRefundRequest(String userId, String orderId, String reason) async {
    final docRef = _firestore.collection('refunds').doc();
    final refundData = {
      'refundId': docRef.id,
      'userId': userId,
      'orderId': orderId,
      'reason': reason.trim(),
      'createdAt': DateTime.now().toIso8601String(),
    };
    
    await _firestore.runTransaction((transaction) async {
      transaction.set(docRef, refundData);
      transaction.update(_firestore.collection('orders').doc(orderId), {'isRequested': true});
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
}
