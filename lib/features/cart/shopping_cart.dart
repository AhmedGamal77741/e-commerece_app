import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/core/helpers/basetime.dart';
import 'package:ecommerece_app/core/helpers/extensions.dart';
import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/features/cart/delete_func.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class ShoppingCart extends StatefulWidget {
  const ShoppingCart({super.key});

  @override
  State<ShoppingCart> createState() => _ShoppingCartState();
}

class _ShoppingCartState extends State<ShoppingCart> {
  // Function to calculate total cart price
  Future<int> calculateCartTotal(List<QueryDocumentSnapshot> cartDocs) async {
    int total = 0;

    for (final cartDoc in cartDocs) {
      final cartData = cartDoc.data() as Map<String, dynamic>;
      final price = cartData['price'];

      try {
        total += (price as int);
      } catch (e) {}
    }

    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            child: StreamBuilder(
              stream:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser?.uid ?? '')
                      .collection('cart')
                      .snapshots(),
              builder: (context, cartSnapshot) {
                if (cartSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                final cartDocs = cartSnapshot.data!.docs;

                return ListView.separated(
                  separatorBuilder: (context, index) {
                    if (index == cartDocs.length - 1) {
                      return SizedBox.shrink();
                    }
                    return Divider();
                  },
                  itemCount: cartDocs.length,
                  itemBuilder: (ctx, index) {
                    final cartData = cartDocs[index].data();
                    final productId = cartData['product_id'];

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
                            productSnapshot.data!.data()
                                as Map<String, dynamic>;

                        return Row(
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
                              padding: EdgeInsets.only(left: 10.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    productData['sellerName'],
                                    style: TextStyles.abeezee14px400wP600,
                                  ),

                                  Text(
                                    productData['productName'],
                                    style: TextStyles.abeezee16px400wPblack,
                                  ),

                                  Row(
                                    children: [
                                      Text(
                                        '수량 : ${cartData['quantity'].toString()}  ',
                                        style: TextStyles.abeezee14px400wP600,
                                      ),
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
                                              style:
                                                  TextStyles
                                                      .abeezee14px400wP600,
                                            );
                                          }
                                          if (snapshot.hasError) {
                                            return Text(
                                              '오류 발생',
                                              style:
                                                  TextStyles
                                                      .abeezee14px400wP600,
                                            );
                                          }

                                          return Text(
                                            '${snapshot.data} 도착예정',
                                            style:
                                                TextStyles.abeezee14px400wP600,
                                          );
                                        },
                                      ),
                                    ],
                                  ),

                                  Text(
                                    '${cartData['price']} 원',
                                    style: TextStyles.abeezee16px400wPblack,
                                  ),
                                ],
                              ),
                            ),

                            Spacer(),
                            IconButton(
                              onPressed: () async {
                                await deleteCartItem(cartDocs[index].id);
                              },
                              icon: Icon(
                                Icons.close,
                                color: ColorsManager.primary600,
                                size: 18,
                              ),
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
        StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser?.uid ?? '')
                  .collection('cart')
                  .snapshots(),
          builder: (context, cartSnapshot) {
            if (!cartSnapshot.hasData || cartSnapshot.data!.docs.isEmpty) {
              return const SizedBox.shrink();
            }
            return FutureBuilder<int>(
              future: calculateCartTotal(cartSnapshot.data!.docs),
              builder: (context, totalSnapshot) {
                return Container(
                  width: 428.w,
                  height: 50.h,
                  decoration: BoxDecoration(color: Colors.white),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 40.w, right: 70.w),
                        child: Text(
                          '총 금액: ',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18.sp,
                            fontFamily: 'ABeeZee',
                            fontWeight: FontWeight.w400,
                            height: 1.40.h,
                          ),
                        ),
                      ),
                      Spacer(),
                      totalSnapshot.hasData
                          ? Padding(
                            padding: EdgeInsets.only(right: 10.w),
                            child: Text(
                              '${totalSnapshot.data} 원',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 18.sp,
                                fontFamily: 'ABeeZee',
                                fontWeight: FontWeight.w400,
                                height: 1.40.h,
                              ),
                            ),
                          )
                          : CircularProgressIndicator(),
                      Padding(
                        padding: EdgeInsets.only(right: 20.w),
                        child: TextButton(
                          onPressed: () {
                            context.go(Routes.placeOrderScreen);
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF121212,
                            ), // Background color
                            foregroundColor: Colors.white, // Text color
                            minimumSize: Size(70.w, 40.h), // Exact dimensions
                            padding: EdgeInsets.zero, // Remove default padding
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                width: 1,
                                color: const Color(0xFF121212),
                              ), // Border
                              borderRadius: BorderRadius.circular(
                                11,
                              ), // Corner radius
                            ),
                            elevation: 0, // Remove shadow
                          ),
                          child: Text(
                            '구매',
                            style: TextStyle(
                              color: const Color(0xFFF5F5F5),
                              fontSize: 16.sp,
                              fontFamily: 'ABeeZee',
                              fontWeight: FontWeight.w400,
                              height: 1.40.h,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
