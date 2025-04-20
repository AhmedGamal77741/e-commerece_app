import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/features/shop/data/product_entity.dart';
import 'package:ecommerece_app/features/shop/data/product_model.dart';

class FirebaseProductRepo {
  final productsCollection = FirebaseFirestore.instance.collection('products');

  Future<List<Product>> getProductsByCategory(String category) async {
    try {
      final snapshot =
          await productsCollection.where('category', isEqualTo: category).get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final entity = ProductEntity.fromDocument(data);
        return Product.fromEntity(entity);
      }).toList();
    } catch (e) {
      log('Error getting products by category: $e');
      rethrow;
    }
  }
}
