import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/core/helpers/basetime.dart';
import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/models/product_model.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/features/shop/fav_fnc.dart';
import 'package:ecommerece_app/features/shop/item_details.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
      child: StreamBuilder(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser?.uid ?? '')
                .collection('favorites')
                .snapshots(),
        builder: (context, favoritesSnapshot) {
          if (favoritesSnapshot.connectionState == ConnectionState.waiting) {
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
                    return ListTile(title: Text('로딩 중...'));
                  }
                  final productData =
                      productSnapshot.data!.data() as Map<String, dynamic>;

                  print(productData);
                  Product p = Product.fromMap(productData);
                  return InkWell(
                    onTap: () async {
                      bool liked = isFavoritedByUser(
                        p: p,
                        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
                      );
                      String arrivalTime = await getArrivalDay(
                        p.meridiem,
                        p.baselineTime,
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ItemDetails(
                                product: p,
                                arrivalDay: arrivalTime,
                              ),
                        ),
                      );

                      // context.pushNamed(
                      //   Routes.itemDetailsScreen,
                      //   arguments: {
                      // 'imgUrl': data['imgUrl'],
                      // 'sellerName': data['sellerName	'],
                      // 'price': data['price	'],
                      // 'product_id': data['product_id'],
                      // 'freeShipping': data['freeShipping	'],
                      // 'meridiem': data['meridiem'],
                      // 'baselinehour': data['baselinehour	'],
                      // 'productName': data['productName	'],
                      //   },
                      // );
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            productData['imgUrl'],
                            width: 106.w,
                            height: 106.h,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: 10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                productData['sellerName'],
                                style: TextStyles.abeezee14px400wP600,
                              ),
                              verticalSpace(5),
                              Text(
                                productData['productName'],
                                style: TextStyles.abeezee16px400wPblack,
                              ),
                              verticalSpace(3),
                              FutureBuilder<String>(
                                future: getArrivalDay(
                                  productData['meridiem'],
                                  productData['baselineTime'],
                                ),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Text(
                                      '로딩 중...',
                                      style: TextStyles.abeezee14px400wP600,
                                    );
                                  }
                                  if (snapshot.hasError) {
                                    return Text(
                                      '오류 발생',
                                      style: TextStyles.abeezee14px400wP600,
                                    );
                                  }

                                  return Text(
                                    '${snapshot.data} 도착예정',
                                    style: TextStyles.abeezee14px400wP600,
                                  );
                                },
                              ),
                              verticalSpace(3),
                              Text(
                                '${productData['pricePoints'][0]['price']} 원',
                                style: TextStyles.abeezee16px400wPblack,
                              ),
                            ],
                          ),
                        ),
                        Spacer(),
                        IconButton(
                          onPressed: () async {
                            // Code to remove the product from favorites
                            await removeProductFromFavorites(
                              userId: FirebaseAuth.instance.currentUser!.uid,
                              productId: productData['product_id'],
                            );
                          },
                          icon: Icon(Icons.close, size: 18),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
  // Function to remove a product from favorites
//   Future<void> removeProductFromFavorites({
//     required String userId,
//     required String productId,
//   }) async {
//     final favoritesRef = FirebaseFirestore.instance
//         .collection('users')
//         .doc(userId)
//         .collection('favorites');

//     // Query for the product that matches the productId
//     final querySnapshot =
//         await favoritesRef.where('product_id', isEqualTo: productId).get();

//     // Check if the product exists in favorites
//     if (querySnapshot.docs.isNotEmpty) {
//       // Loop through all documents found (should be only one)
//       for (var doc in querySnapshot.docs) {
//         // Delete the document
//         await doc.reference.delete();
//       }
//     } else {
//       print("Product not found in favorites.");
//     }
//   }
// }
  