import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> addProductToFavorites({
  required String userId,
  required String productId,
}) async {
  final favoritesRef = FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('favorites');

  final newDocRef = favoritesRef.doc();
  await newDocRef.set({'favorite_id': newDocRef.id, 'product_id': productId});
}

Future<void> removeProductFromFavorites({
  required String userId,
  required String productId,
}) async {
  final favoritesRef = FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('favorites');

  // Query for the product that matches the productId
  final querySnapshot =
      await favoritesRef.where('product_id', isEqualTo: productId).get();

  // Check if the product exists in favorites
  if (querySnapshot.docs.isNotEmpty) {
    // Loop through all documents found (should be only one)
    for (var doc in querySnapshot.docs) {
      // Delete the document
      await doc.reference.delete();
    }
  } else {
    print("Product not found in favorites.");
  }
}

Future<bool> isProductInFavorites(String userId, String productId) async {
  try {
    // Reference to the user's favorites collection in Firestore
    final favsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('favorites');

    // Query to check if the product exists in the user's favorites
    final querySnapshot =
        await favsRef.where('product_id', isEqualTo: productId).get();

    // If the query returns at least one document, the product is in favorites
    return querySnapshot.docs.isNotEmpty;
  } catch (e) {
    // Handle error
    print("Error checking favorite product: $e");
    return false;
  }
}
