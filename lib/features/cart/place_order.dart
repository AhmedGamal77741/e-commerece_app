import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/core/helpers/basetime.dart';
import 'package:ecommerece_app/core/helpers/extensions.dart';
import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/core/widgets/underline_text_filed.dart';
import 'package:ecommerece_app/core/widgets/wide_text_button.dart';
import 'package:ecommerece_app/features/cart/delete_func.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PlaceOrder extends StatefulWidget {
  const PlaceOrder({super.key});

  @override
  State<PlaceOrder> createState() => _PlaceOrderState();
}

class _PlaceOrderState extends State<PlaceOrder> {
  final deliveryAddressController = TextEditingController();
  final deliveryInstructionsController = TextEditingController();
  final cashReceiptController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          centerTitle: true,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios),
          ),
          title: Text("주문하기", style: TextStyle(fontFamily: 'ABeeZee')),
        ),
        body: Padding(
          padding: EdgeInsets.only(left: 15.w, top: 30.h, right: 15.w),
          child: ListView(
            children: [
              Container(
                padding: EdgeInsets.only(left: 15.w, top: 15.h, bottom: 15.h),
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      width: 0.27,
                      color: const Color(0xFF747474),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 16.h,
                    children: [
                      Text(
                        '배송지 주소',
                        style: TextStyle(
                          color: const Color(0xFF121212),
                          fontSize: 16.sp,
                          fontFamily: 'ABeeZee',
                          fontWeight: FontWeight.w400,
                          height: 1.40.h,
                        ),
                      ),
                      UnderlineTextField(
                        controller: deliveryAddressController,
                        hintText: '이름을 입력하세요',
                        obscureText: false,
                        keyboardType: TextInputType.text,
                        validator: (val) {
                          if (val!.isEmpty) {
                            return '이름을 입력하세요';
                          } else if (val.length > 30) {
                            return '이름이 너무 깁니다';
                          }
                          return null;
                        },
                      ),

                      Text(
                        '배송 지침',
                        style: TextStyle(
                          color: const Color(0xFF121212),
                          fontSize: 16.sp,
                          fontFamily: 'ABeeZee',
                          fontWeight: FontWeight.w400,
                          height: 1.40.h,
                        ),
                      ),
                      UnderlineTextField(
                        controller: deliveryInstructionsController,
                        hintText: '이름을 입력하세요',
                        obscureText: false,
                        keyboardType: TextInputType.text,
                        validator: (val) {
                          if (val!.isEmpty) {
                            return '이름을 입력하세요';
                          } else if (val.length > 30) {
                            return '이름이 너무 깁니다';
                          }
                          return null;
                        },
                      ),

                      Text(
                        '지불',
                        style: TextStyle(
                          color: const Color(0xFF121212),
                          fontSize: 16.sp,
                          fontFamily: 'ABeeZee',
                          fontWeight: FontWeight.w400,
                          height: 1.40.h,
                        ),
                      ),
                      Text(
                        '네이버 페이 (빠른 결제)',
                        style: TextStyle(
                          color: const Color(0xFF747474),
                          fontSize: 14.sp,
                          fontFamily: 'ABeeZee',
                          fontWeight: FontWeight.w400,
                          height: 1.40.h,
                        ),
                      ),

                      Divider(),

                      Text(
                        '현금 영수증',
                        style: TextStyle(
                          color: const Color(0xFF121212),
                          fontSize: 16.sp,
                          fontFamily: 'ABeeZee',
                          fontWeight: FontWeight.w400,
                          height: 1.40.h,
                        ),
                      ),
                      UnderlineTextField(
                        controller: cashReceiptController,
                        hintText: '이름을 입력하세요',
                        obscureText: false,
                        keyboardType: TextInputType.text,
                        validator: (val) {
                          if (val!.isEmpty) {
                            return '이름을 입력하세요';
                          } else if (val.length > 30) {
                            return '이름이 너무 깁니다';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              verticalSpace(20),
              Container(
                padding: EdgeInsets.only(left: 15.w, top: 15.h, bottom: 15.h),
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      width: 0.27,
                      color: const Color(0xFF747474),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: StreamBuilder(
                  stream:
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(FirebaseAuth.instance.currentUser?.uid ?? '')
                          .collection('cart')
                          .snapshots(),
                  builder: (context, cartSnapshot) {
                    if (cartSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    final cartDocs = cartSnapshot.data!.docs;

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
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

                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 12.h,
                              children: [
                                Text(
                                  '${productData['productName']} / 수량 : ${cartData['quantity'].toString()}',
                                  style: TextStyle(
                                    color: const Color(0xFF747474),
                                    fontSize: 14.sp,
                                    fontFamily: 'ABeeZee',
                                    fontWeight: FontWeight.w400,
                                    height: 1.40.h,
                                  ),
                                ),

                                Text(
                                  '${(productData['price'] * cartData['quantity']).toString()} KRW',
                                  style: TextStyle(
                                    color: const Color(0xFF747474),
                                    fontSize: 14.sp,
                                    fontFamily: 'ABeeZee',
                                    fontWeight: FontWeight.w600,
                                    height: 1.40.h,
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
              verticalSpace(20),
              StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser?.uid ?? '')
                        .collection('cart')
                        .snapshots(),
                builder: (context, cartSnapshot) {
                  if (!cartSnapshot.hasData ||
                      cartSnapshot.data!.docs.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return FutureBuilder<int>(
                    future: calculateCartTotal(cartSnapshot.data!.docs),
                    builder: (context, totalSnapshot) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,

                        spacing: 12.h,
                        children: [
                          verticalSpace(20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total : ',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 18.sp,
                                  fontFamily: 'ABeeZee',
                                  fontWeight: FontWeight.w400,
                                  height: 1.40.h,
                                ),
                              ),
                              totalSnapshot.hasData
                                  ? Text(
                                    '${totalSnapshot.data} KRW',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 18.sp,
                                      fontFamily: 'ABeeZee',
                                      fontWeight: FontWeight.w400,
                                      height: 1.40.h,
                                    ),
                                  )
                                  : CircularProgressIndicator(),
                            ],
                          ),
                          verticalSpace(20),
                          WideTextButton(
                            txt: '주문하기',
                            func: () async {
                              if (!_formKey.currentState!.validate()) return;
                              final user = FirebaseAuth.instance.currentUser;
                              if (user == null) return;
                              final cartSnapshot =
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(user.uid)
                                      .collection('cart')
                                      .get();
                              final cartItems =
                                  cartSnapshot.docs
                                      .map((doc) => doc.data())
                                      .toList();
                              final totalAmount = totalSnapshot.data;

                              final docRef =
                                  FirebaseFirestore.instance
                                      .collection('orders')
                                      .doc();
                              final orderId = docRef.id;
                              final orderData = {
                                'orderId': orderId,
                                'userId': user.uid,
                                'deliveryAddress':
                                    deliveryAddressController.text.trim(),
                                'deliveryInstructions':
                                    deliveryInstructionsController.text.trim(),
                                'cashReceipt':
                                    cashReceiptController.text.trim(),
                                'paymentMethod': 'naver pay',
                                'orderDate': DateTime.now().toIso8601String(),
                                'totalPrice': totalAmount,
                                'status': 'pending',
                                'items':
                                    cartItems
                                        .map(
                                          (item) => {
                                            'productId': item['product_id'],
                                            'quantity': item['quantity'],
                                          },
                                        )
                                        .toList(),
                              };
                              try {
                                await docRef.set(orderData);
                                for (var doc in cartSnapshot.docs) {
                                  await doc.reference.delete();
                                  mounted;

                                  context.pushReplacementNamed(
                                    Routes.orderCompleteScreen,
                                  );
                                }
                              } catch (e) {
                                print('Failed to place order: $e');
                              }
                            },
                            color: Colors.black,
                            txtColor: Colors.white,
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<int> calculateCartTotal(List<QueryDocumentSnapshot> cartDocs) async {
  int total = 0;

  for (final cartDoc in cartDocs) {
    final cartData = cartDoc.data() as Map<String, dynamic>;
    final productId = cartData['product_id'];

    try {
      final productSnapshot =
          await FirebaseFirestore.instance
              .collection('products')
              .doc(productId)
              .get();

      if (productSnapshot.exists) {
        final productData = productSnapshot.data() as Map<String, dynamic>;
        total += (productData['price'] as int) * (cartData['quantity'] as int);
      }
    } catch (e) {
      debugPrint('Error calculating price for product $productId: $e');
    }
  }

  return total;
}
