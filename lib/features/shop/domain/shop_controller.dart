import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/core/providers/firebase_providers.dart';
import 'package:ecommerece_app/core/models/product_model.dart';
import 'package:ecommerece_app/features/shop/data/shop_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final shopControllerProvider = Provider<ShopController>((ref) {
  return ShopController(ref);
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

  final firestore = FirebaseFirestore.instance;
  return firestore.collection('users').doc(user.uid).snapshots().asyncMap((userDoc) async {
    if (!userDoc.exists) return null;
    final defaultAddressId = userDoc.data()?['defaultAddressId'] as String?;
    if (defaultAddressId == null || defaultAddressId.isEmpty) return null;

    final addressDoc = await firestore
        .collection('users')
        .doc(user.uid)
        .collection('addresses')
        .doc(defaultAddressId)
        .get();
        
    if (!addressDoc.exists) return null;
    return addressDoc.data();
  });
});

class ShopController {
  final Ref _ref;
  ShopController(this._ref);
  
  Future<QuerySnapshot<Map<String, dynamic>>> getAllProducts() {
    return _ref.read(shopRepositoryProvider).getAllProducts();
  }
}
