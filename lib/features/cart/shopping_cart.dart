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

class ShoppingCart extends StatefulWidget {
  const ShoppingCart({super.key});

  @override
  State<ShoppingCart> createState() => _ShoppingCartState();
}

class _ShoppingCartState extends State<ShoppingCart> {
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
                            Image.network(
                              productData['imgUrl'],
                              width: 90.w,
                              height: 90.h,
                              fit: BoxFit.cover,
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
                                  verticalSpace(5),
                                  Text(
                                    productData['productName'],
                                    style: TextStyles.abeezee13px400wPblack,
                                  ),
                                  verticalSpace(3),

                                  Row(
                                    children: [
                                      Text(
                                        '수량 : ${cartData['quantity'].toString()}  ',
                                        style: TextStyles.abeezee11px400wP600,
                                      ),
                                      Text(
                                        '${getArrivalDay(productData['meridiem'], productData['baselineTime'])} ',
                                        style: TextStyles.abeezee11px400wP600,
                                      ),
                                    ],
                                  ),

                                  Text(
                                    '${(productData['price'] * cartData['quantity']).toString()} KRW',
                                    style: TextStyles.abeezee13px400wPblack,
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
        Container(
          width: 428.w,
          height: 50.h,
          decoration: BoxDecoration(color: Colors.white),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Padding(
                padding: EdgeInsets.only(left: 40.w, right: 70.w),
                child: Text(
                  '합계 : ',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18.sp,
                    fontFamily: 'ABeeZee',
                    fontWeight: FontWeight.w400,
                    height: 1.40.h,
                  ),
                ),
              ),

              Text(
                'KRW',

                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18.sp,
                  fontFamily: 'ABeeZee',
                  fontWeight: FontWeight.w400,
                  height: 1.40.h,
                ),
              ),
              TextButton(
                onPressed: () {
                  context.pushNamed(Routes.placeOrderScreen);
                },
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF121212), // Background color
                  foregroundColor: Colors.white, // Text color
                  minimumSize: Size(102.w, 26.h), // Exact dimensions
                  padding: EdgeInsets.zero, // Remove default padding
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      width: 1,
                      color: const Color(0xFF121212),
                    ), // Border
                    borderRadius: BorderRadius.circular(8), // Corner radius
                  ),
                  elevation: 0, // Remove shadow
                ),
                child: Text(
                  '주문하기',
                  style: TextStyle(
                    color: const Color(0xFFF5F5F5),
                    fontSize: 16.sp,
                    fontFamily: 'ABeeZee',
                    fontWeight: FontWeight.w400,
                    height: 1.40.h,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
