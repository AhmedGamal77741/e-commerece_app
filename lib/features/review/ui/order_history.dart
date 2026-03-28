import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/core/helpers/basetime.dart';
import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/core/widgets/black_text_button.dart';
import 'package:ecommerece_app/features/review/ui/exchange_or_refund.dart';
import 'package:ecommerece_app/features/review/ui/track_order.dart';
import 'package:ecommerece_app/features/review/ui/widgets/text_and_buttons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OrderHistory extends StatefulWidget {
  const OrderHistory({super.key});

  @override
  State<OrderHistory> createState() => _OrderHistoryState();
}

class _OrderHistoryState extends State<OrderHistory> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;
        if (user == null) {
          return Center(child: Text('내 페이지 탭에서 회원가입 후 이용가능합니다.'));
        }

        final orderStream =
            FirebaseFirestore.instance
                .collection('orders')
                .where('userId', isEqualTo: user.uid)
                .snapshots();

        return StreamBuilder<QuerySnapshot>(
          stream: orderStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('주문이 없습니다.'));
            }

            final orders = snapshot.data!.docs;

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              child: ListView.separated(
                itemCount: orders.length,
                separatorBuilder:
                    (context, index) =>
                        Divider(color: ColorsManager.primary300),
                itemBuilder: (context, index) {
                  final data = orders[index].data() as Map<String, dynamic>;
                  return FutureBuilder<Map<String, dynamic>>(
                    future: fetchProductDetails(data['productId']),
                    builder: (context, productSnapshot) {
                      if (productSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!productSnapshot.hasData ||
                          productSnapshot.data!.isEmpty) {
                        return const Center(
                          child: Text('No products found for this order.'),
                        );
                      }
                      // Get the product data
                      final product = productSnapshot.data!;
                      print(isDispatched(product, data['orderDate']));
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              product['imgUrl'],
                              width: 120.w,
                              height: 120.h,
                              fit: BoxFit.cover,
                            ),
                          ),
                          horizontalSpace(10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextAndButtons(
                                  sellerName: product['sellerName'],
                                  productName: product['productName'],
                                  qunatity: data['quantity'].toString(),
                                  orderPrice: data['totalPrice'],
                                  baselineTime: product['baselineTime'],
                                  meridiem: product['meridiem'],
                                ),
                                Row(
                                  children: [
                                    BlackTextButton(
                                      txt: '배송조회',
                                      style: TextStyles.abeezee14px400wW,
                                      func: () async {
                                        String arrivalDate =
                                            await getArrivalDay2(
                                              product['meridiem'],
                                              product['baselineTime'],
                                            );
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) => TrackOrder(
                                                  order: data,
                                                  arrivalDate: arrivalDate,
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                                    horizontalSpace(5),
                                    data['confirmed']
                                        ? (data['isRequested']
                                            ? BlackTextButton(
                                              txt: '교환 · 반품 신청',
                                              style: TextStyles.abeezee14px400wW
                                                  .copyWith(
                                                    decoration:
                                                        TextDecoration
                                                            .lineThrough,
                                                    decorationColor: Colors.red,
                                                    decorationThickness: 2,
                                                  ),
                                              func: () {},
                                            )
                                            : BlackTextButton(
                                              txt: '교환 · 반품 신청',
                                              style:
                                                  TextStyles.abeezee14px400wW,
                                              func: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (
                                                          context,
                                                        ) => ExchangeOrRefund(
                                                          userId: user.uid,
                                                          orderId:
                                                              data['orderId'],
                                                        ),
                                                  ),
                                                );
                                              },
                                            ))
                                        : BlackTextButton(
                                          txt: '주문취소',
                                          style: TextStyles.abeezee14px400wW,
                                          func: () async {
                                            await deleteOrder(data, context);
                                          },
                                        ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              // maybe show options for details
                            },
                            icon: Icon(
                              Icons.more_horiz,
                              color: ColorsManager.primary600,
                              size: 18,
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

Future<Map<String, dynamic>> fetchProductDetails(String productId) async {
  DocumentSnapshot productSnapshot =
      await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .get();

  if (productSnapshot.exists) {
    Map<String, dynamic> productData =
        productSnapshot.data() as Map<String, dynamic>;

    return productData;
  }

  return {}; // Return an empty map instead of null
}

bool isDispatched(Map<String, dynamic> product, String orderDate) {
  DateTime now = DateTime.now();
  DateTime orderTime = DateTime.parse(orderDate);

  DateTime adjustedTime;
  DateTime nextDay;

  int adjustedHour = product['baselineTime'];

  if (product['meridiem'].toLowerCase() == 'pm' &&
      product['baselineTime'] < 12) {
    adjustedHour += 12; // Convert PM to 24-hour format
  } else if (product['meridiem'].toLowerCase() == 'am' &&
      product['baselineTime'] == 12) {
    adjustedHour = 0; // Convert 12 AM to 0 hours (midnight)
  }
  adjustedTime = DateTime(
    orderTime.year,
    orderTime.month,
    orderTime.day,
    adjustedHour,
    orderTime.minute,
    orderTime.second,
    orderTime.millisecond,
    orderTime.microsecond,
  );
  nextDay = adjustedTime.add(Duration(days: 1));
  if (orderTime.isBefore(adjustedTime) && now.isAfter(adjustedTime)) {
    return true;
  } else if (orderTime.isAfter(adjustedTime) && now.isAfter(nextDay)) {
    return true;
  }

  return false;
}

Future<void> deleteOrder(
  Map<String, dynamic> order,
  BuildContext context,
) async {
  final navigator = Navigator.of(context);
  final scaffoldMessenger = ScaffoldMessenger.of(context);

  // Debug: Print order map
  print('🟡 deleteOrder called with order:');
  order.forEach((k, v) => print('  $k: $v'));

  // 1. Confirm with user
  bool? confirmed = await showDialog<bool>(
    context: context,
    builder:
        (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            '주문취소',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            '정말로 주문을 취소하시겠습니까?\n취소 시 결제 금액이 환불됩니다.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              child: const Text('취소', style: TextStyle(color: Colors.black)),
              onPressed: () => navigator.pop(false),
            ),
            TextButton(
              child: const Text('확인', style: TextStyle(color: Colors.white)),
              style: TextButton.styleFrom(backgroundColor: Colors.black),
              onPressed: () => navigator.pop(true),
            ),
          ],
        ),
  );

  if (confirmed != true) return;

  // 2. Show loading
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const Center(child: CircularProgressIndicator()),
  );

  try {
    // 3. Check user authentication
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      navigator.pop();
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    // 4. Validate order input
    final orderId = order['orderId'] as String?;
    final refundTotalRaw = order['totalPrice'];
    final refundTotal =
        (refundTotalRaw is int)
            ? refundTotalRaw
            : (refundTotalRaw is double)
            ? refundTotalRaw.toInt()
            : int.tryParse(refundTotalRaw.toString());
    final uid = user.uid;
    print(
      '🟡 orderId: $orderId, refundTotal: $refundTotal, uid: $uid (raw: $refundTotalRaw, type: ${refundTotalRaw.runtimeType})',
    );
    if (orderId == null || refundTotal == null) {
      navigator.pop();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            '주문 정보가 올바르지 않습니다. (orderId: $orderId, refundTotal: $refundTotal) (raw: $refundTotalRaw, type: ${refundTotalRaw.runtimeType})',
          ),
        ),
      );
      return;
    }

    // 5. Call Cloud Function (onCall, expects {uid, orderId, type})
    final callable = FirebaseFunctions.instance.httpsCallable('requestRefund');
    final result = await callable.call({
      'uid': uid,
      'orderId': orderId,
      'type': 'cancel',
    });

    navigator.pop(); // Remove loading

    final data = result.data;
    print(data);
    if (data != null &&
        (data['status'] == 'refunded' || data['status'] == 'canceled')) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('주문이 성공적으로 취소되었습니다.')),
      );
    } else {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('주문 취소에 실패했습니다. 다시 시도해주세요.')),
      );
    }
  } catch (e) {
    navigator.pop(); // Remove loading
    String errorMessage = '주문 취소 중 오류가 발생했습니다. 다시 시도해주세요.';
    print('❌ Unexpected error: $e');
    scaffoldMessenger.showSnackBar(SnackBar(content: Text(errorMessage)));
  }
}
