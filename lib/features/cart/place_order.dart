import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/core/helpers/extensions.dart';
import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/core/widgets/underline_text_filed.dart';
import 'package:ecommerece_app/core/widgets/wide_text_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

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
          title: Text("주문 결제", style: TextStyle(fontFamily: 'ABeeZee')),
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
                    spacing: 5.h,
                    children: [
                      Text(
                        '베송지',
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
                        hintText: '기본 배송지 : ',
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
                        '배송 요청사항',
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
                        hintText: '문앞',
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
                        '결제',
                        style: TextStyle(
                          color: const Color(0xFF121212),
                          fontSize: 16.sp,
                          fontFamily: 'ABeeZee',
                          fontWeight: FontWeight.w400,
                          height: 1.40.h,
                        ),
                      ),
                      verticalSpace(5),
                      Text(
                        '간편결제',
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
                        hintText: '현금영수증 정보',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('구매목록', style: TextStyles.abeezee16px400wPblack),
                    verticalSpace(10),
                    StreamBuilder(
                      stream:
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(FirebaseAuth.instance.currentUser?.uid ?? '')
                              .collection('cart')
                              .snapshots(),
                      builder: (context6, cartSnapshot) {
                        if (cartSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        final cartDocs = cartSnapshot.data!.docs;

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          separatorBuilder: (context5, index) {
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
                              builder: (context4, productSnapshot) {
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
                                      '${(cartData['price']).toString()} 원',
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
                  ],
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
                builder: (context3, cartSnapshot) {
                  if (!cartSnapshot.hasData ||
                      cartSnapshot.data!.docs.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return FutureBuilder<int>(
                    future: calculateCartTotal(cartSnapshot.data!.docs),
                    builder: (context2, totalSnapshot) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,

                        spacing: 12.h,
                        children: [
                          verticalSpace(20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '총 결제 금액 ',
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
                                    '${totalSnapshot.data} 원',
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
                          verticalSpace(5),
                          WideTextButton(
                            txt: '주문',
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

                              try {
                                // Step 1: Validate stock for all items
                                for (var item in cartItems) {
                                  final productId = item['product_id'];
                                  final quantityOrdered = item['quantity'];

                                  final productRef = FirebaseFirestore.instance
                                      .collection('products')
                                      .doc(productId);
                                  final productSnapshot =
                                      await productRef.get();

                                  if (!productSnapshot.exists) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Product with ID $productId no longer exists.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  final currentStock =
                                      productSnapshot.data()?['stock'] ?? 0;

                                  if (currentStock < quantityOrdered) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Not enough stock for product ID $productId.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                }

                                // Step 2: Create an order document **for each product**
                                for (var item in cartItems) {
                                  final productId = item['product_id'];
                                  final quantityOrdered = item['quantity'];
                                  final price = item['price'];

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
                                        deliveryInstructionsController.text
                                            .trim(),
                                    'cashReceipt':
                                        cashReceiptController.text.trim(),
                                    'paymentMethod': 'naver pay',
                                    'orderDate':
                                        DateTime.now().toIso8601String(),
                                    'totalPrice': price,
                                    'productId': productId,
                                    'quantity': quantityOrdered,
                                    "courier": '',
                                    "trackingNumber": '',
                                    "trackingEvents": [],
                                    "orderStatus": "orderComplete",
                                    'isRequested': false,
                                    'deliveryManagerId': '',
                                  };

                                  await docRef.set(orderData);

                                  // Step 3: Update stock
                                  final productRef = FirebaseFirestore.instance
                                      .collection('products')
                                      .doc(productId);
                                  await productRef.update({
                                    'stock': FieldValue.increment(
                                      -quantityOrdered,
                                    ),
                                  });
                                }

                                // Step 4: Clear cart
                                for (var doc in cartSnapshot.docs) {
                                  await doc.reference.delete();
                                }

                                if (mounted) {
                                  context.go(Routes.orderCompleteScreen);
                                }
                              } catch (e) {
                                print('Failed to place order: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Failed to place order. Please try again.',
                                    ),
                                  ),
                                );
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
    final price = cartData['price'];

    try {
      total += price as int;
    } catch (e) {}
  }

  return total;
}
