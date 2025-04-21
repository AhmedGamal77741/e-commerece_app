import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
            child: StreamBuilder(
              stream:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser?.uid ?? '')
                      .collection('favorites')
                      .snapshots(),
              builder: (context, favoritesSnapshot) {
                if (favoritesSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                final favoritesDocs = favoritesSnapshot.data!.docs;

                return ListView.separated(
                  separatorBuilder: (context, index) {
                    if (index == favoritesDocs.length - 1) {
                      return SizedBox.shrink();
                    }
                    return Divider();
                  },
                  itemCount: favoritesDocs.length,
                  itemBuilder: (ctx, index) {
                    final favoriteData = favoritesDocs[index].data();
                    final productId = favoriteData['product_id'];

                    return FutureBuilder<DocumentSnapshot>(
                      future:
                          FirebaseFirestore.instance
                              .collection('products')
                              .doc(productId)
                              .get(),
                      builder: (context, productSnapshot) {
                        if (!productSnapshot.hasData) {
                          return ListTile(title: Text('Loading...'));
                        }
                        final productData =
                            productSnapshot.data!.data()
                                as Map<String, dynamic>;

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.network(
                              productData['imgUrl'],
                              width: 90.0,
                              height: 90.0,
                              fit: BoxFit.cover,
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    productData['sellerName	'],
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    productData['productName	'],
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                ],
                              ),
                            ),
                            Spacer(),
                            IconButton(
                              onPressed: () async {
                                // Code to remove the product from favorites
                                await removeProductFromFavorites(
                                  userId:
                                      FirebaseAuth.instance.currentUser!.uid,
                                  productId: productId,
                                );
                              },
                              icon: Icon(Icons.close, size: 18),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // Function to remove a product from favorites
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
}
