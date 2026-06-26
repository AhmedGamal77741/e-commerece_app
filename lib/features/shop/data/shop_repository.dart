import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final shopRepositoryProvider = Provider<ShopRepository>((ref) {
  return ShopRepository(FirebaseFirestore.instance);
});

class ShopRepository {
  final FirebaseFirestore _firestore;

  ShopRepository(this._firestore);

  Stream<QuerySnapshot<Map<String, dynamic>>> categoriesStream() {
    return _firestore
        .collection('categories')
        .orderBy('order')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> productsByCategoryStream(String categoryId) {
    if (categoryId == 'all') {
      return _firestore.collection('products').snapshots();
    }
    return _firestore
        .collection('products')
        .where('categoryId', isEqualTo: categoryId)
        .snapshots();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getAllProducts() {
    return _firestore.collection('products').get();
  }
}
