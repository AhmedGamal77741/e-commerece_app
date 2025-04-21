import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> addProductAsNewEntryToCart({
  required String userId,
  required String productId,
  required int quantity,
}) async {
  final cartRef = FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('cart');

  await cartRef.add({
    'cart_id': cartRef.doc().id, // optional if you want to use the doc ID
    'product_id': productId,
    'quantity': quantity,
    'added_at': FieldValue.serverTimestamp(),
  });
}
