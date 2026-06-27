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
}
