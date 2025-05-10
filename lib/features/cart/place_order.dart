import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/core/helpers/extensions.dart';
import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/core/widgets/underline_text_filed.dart';
import 'package:ecommerece_app/core/widgets/wide_text_button.dart';
import 'package:ecommerece_app/features/cart/models/address.dart';
import 'package:ecommerece_app/features/cart/services/kakao_service.dart';
import 'package:ecommerece_app/features/cart/sub_screens/add_address_screen.dart';
import 'package:ecommerece_app/features/cart/sub_screens/address_list_screen.dart';
import 'package:ecommerece_app/features/cart/sub_screens/address_search_dialog.dart';
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
  final phoneController = TextEditingController();
  int selectedOption = 1;
  final _formKey = GlobalKey<FormState>();
  Address address = Address(
    name: '',
    phone: '',
    address: '',
    detailAddress: '',
    isDefault: false,
    addressMap: {},
  );
  final List<String> deliveryRequests = [
    '문앞', // "At the door"
    '직접 받고 부재 시 문앞', // "Security office"
    '택배함', // "Parcel box"
    '경비실', // "Receive directly"
    '직접입력', // "Other"
  ];
  String selectedRequest = '문앞';
  Future<void> _selectAddress() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddressListScreen()),
    );

    if (result != null) {
      deliveryAddressController.text = result.address;
      setState(() {
        address = result;
      });
    }
  }

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
                padding: EdgeInsets.only(
                  left: 15.w,
                  top: 15.h,
                  bottom: 15.h,
                  right: 15.w,
                ),
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
                      Container(
                        padding: EdgeInsets.only(bottom: 5.h),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: ColorsManager.primary400,
                              width: 1.0,
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child:
                                  address.name.isEmpty
                                      ? FutureBuilder(
                                        future:
                                            FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(
                                                  FirebaseAuth
                                                      .instance
                                                      .currentUser!
                                                      .uid,
                                                )
                                                .get(),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            );
                                          }

                                          if (snapshot.hasError) {
                                            return Center(
                                              child: Text(
                                                'Error loading user address: ${snapshot.error}',
                                              ),
                                            );
                                          }

                                          if (!snapshot.hasData ||
                                              !snapshot.data!.exists) {
                                            return Center(
                                              child: Text(
                                                'User data not found',
                                              ),
                                            );
                                          }

                                          final userData =
                                              snapshot.data?.data();
                                          if (userData == null ||
                                              userData['defaultAddressId'] ==
                                                  null ||
                                              userData['defaultAddressId'] ==
                                                  '') {
                                            return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '배송지 미설정',
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 15.sp,
                                                    fontFamily: 'ABeeZee',
                                                    fontWeight: FontWeight.w400,
                                                    height: 1.40.h,
                                                  ),
                                                ),
                                                SizedBox(height: 8.h),
                                                Text(
                                                  '배송지를 설정해주세요',
                                                  style: TextStyle(
                                                    fontSize: 15.sp,
                                                    color: Color(0xFF9E9E9E),
                                                    fontFamily: 'ABeeZee',
                                                  ),
                                                ),
                                              ],
                                            );
                                          }
                                          return FutureBuilder(
                                            future:
                                                FirebaseFirestore.instance
                                                    .collection('users')
                                                    .doc(
                                                      FirebaseAuth
                                                          .instance
                                                          .currentUser!
                                                          .uid,
                                                    )
                                                    .collection('addresses')
                                                    .doc(
                                                      userData!['defaultAddressId'],
                                                    )
                                                    .get(),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState ==
                                                  ConnectionState.waiting) {
                                                return Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                );
                                              }

                                              if (snapshot.hasError) {
                                                return Center(
                                                  child: Text(
                                                    'Error loading user address: ${snapshot.error}',
                                                  ),
                                                );
                                              }

                                              if (!snapshot.hasData ||
                                                  !snapshot.data!.exists) {
                                                return Center(
                                                  child: Text(
                                                    'User data not found',
                                                  ),
                                                );
                                              }

                                              final addressData =
                                                  snapshot.data?.data();
                                              return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '베송지 | ${addressData!['name']}',
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 15.sp,
                                                      fontFamily: 'ABeeZee',
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      height: 1.40.h,
                                                    ),
                                                  ),
                                                  SizedBox(height: 8.h),

                                                  Text(
                                                    addressData['phone'],
                                                    style: TextStyle(
                                                      fontSize: 15.sp,
                                                      color: Color(0xFF9E9E9E),
                                                      fontFamily: 'ABeeZee',
                                                    ),
                                                  ),
                                                  Text(
                                                    addressData['address'],
                                                    style: TextStyle(
                                                      fontSize: 15.sp,
                                                      color: Color(0xFF9E9E9E),
                                                      fontFamily: 'ABeeZee',
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      )
                                      : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '베송지 | ${address.name}',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 15.sp,
                                              fontFamily: 'ABeeZee',
                                              fontWeight: FontWeight.w400,
                                              height: 1.40.h,
                                            ),
                                          ),
                                          SizedBox(height: 8.h),

                                          Text(
                                            address.phone,
                                            style: TextStyle(
                                              fontSize: 15.sp,
                                              color: Color(0xFF9E9E9E),
                                              fontFamily: 'ABeeZee',
                                            ),
                                          ),
                                          Text(
                                            address.detailAddress,
                                            style: TextStyle(
                                              fontSize: 15.sp,
                                              color: Color(0xFF9E9E9E),
                                              fontFamily: 'ABeeZee',
                                            ),
                                          ),
                                        ],
                                      ),
                            ),
                            TextButton(
                              onPressed: _selectAddress,

                              style: TextButton.styleFrom(
                                fixedSize: Size(48.w, 30.h),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                side: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1.0,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                              ),
                              child: Text(
                                '변경',
                                style: TextStyle(
                                  color: ColorsManager.primaryblack,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 15.h),
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
                      StatefulBuilder(
                        builder: (context, setStateDropdown) {
                          return DropdownButtonFormField<String>(
                            value: selectedRequest,
                            dropdownColor: Colors.white,
                            items:
                                deliveryRequests
                                    .map(
                                      (request) => DropdownMenuItem(
                                        value: request,
                                        child: Text(
                                          request,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 16.sp,
                                            fontFamily: 'ABeeZee',
                                            fontWeight: FontWeight.w400,
                                            height: 1.40.h,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                            decoration: const InputDecoration(
                              border: UnderlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 0,
                                vertical: 8,
                              ),
                            ),
                            onChanged: (value) {
                              setStateDropdown(() {
                                selectedRequest = value!;
                              });
                            },
                            icon: Icon(Icons.keyboard_arrow_down),
                          );
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
                      Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: ColorsManager.primary400,
                              width: 1.0,
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              child: TextFormField(
                                controller: cashReceiptController,
                                decoration: InputDecoration(
                                  hintText: '국민은행 / 0000000000000',
                                  hintStyle: TextStyle(
                                    fontSize: 15.sp,
                                    color: ColorsManager.primary400,
                                  ),
                                  border: InputBorder.none,
                                ),
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
                            ),
                            TextButton(
                              onPressed: () {},

                              style: TextButton.styleFrom(
                                fixedSize: Size(48.w, 30.h),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                side: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1.0,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                              ),
                              child: Text(
                                '변경',
                                style: TextStyle(
                                  color: ColorsManager.primaryblack,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatefulBuilder(
                        builder: (context, setStateRadio) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Radio(
                                    value: 1,
                                    groupValue: selectedOption,
                                    onChanged: (value) {
                                      setStateRadio(() {
                                        selectedOption = value!;
                                        print("Button value: $value");
                                      });
                                    },
                                  ),
                                  Text(
                                    '현금 영수증',
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      fontFamily: 'ABeeZee',
                                      fontWeight: FontWeight.w400,
                                      color: ColorsManager.primaryblack,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Radio(
                                    value: 2,
                                    groupValue: selectedOption,
                                    onChanged: (value) {
                                      setStateRadio(() {
                                        selectedOption = value!;
                                        print("Button value: $value");
                                      });
                                    },
                                  ),
                                  Text(
                                    '세금 계산서',
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      fontFamily: 'ABeeZee',
                                      fontWeight: FontWeight.w400,
                                      color: ColorsManager.primaryblack,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),

                      UnderlineTextField(
                        controller: phoneController,
                        hintText: '전화번호 ',
                        obscureText: false,
                        keyboardType: TextInputType.phone,
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
