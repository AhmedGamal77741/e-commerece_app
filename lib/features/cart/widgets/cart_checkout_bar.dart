import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/core/models/product_model.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/features/cart/domain/cart_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class CartCheckoutBar extends ConsumerWidget {
  const CartCheckoutBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatCurrency = NumberFormat('#,###');
    final total = ref.watch(cartTotalProvider);
    final cartDocsAsync = ref.watch(userCartStreamProvider);

    if (total == 0) return const SizedBox.shrink();

    return SizedBox(
      width: 428.w,
      height: 50.h,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 30.w, right: 70.w),
            child: Text(
              '총 금액: ',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18.sp,
                fontFamily: 'NotoSans',
                fontWeight: FontWeight.w400,
                height: 1.40.h,
              ),
            ),
          ),
          Spacer(),
          Padding(
            padding: EdgeInsets.only(right: 10.w),
            child: Text(
              '${formatCurrency.format(total)} 원',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18.sp,
                fontFamily: 'NotoSans',
                fontWeight: FontWeight.w400,
                height: 1.40.h,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: 20.w),
            child: TextButton(
              onPressed: () async {
                final cartDocs = cartDocsAsync.value;
                if (cartDocs == null || cartDocs.isEmpty) return;

                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                );

                try {
                  bool hasInsufficientStock = false;
                  String insufficientProductName = '';
                  int remainingQuantity = 0;

                  // Run all product fetches in parallel
                  final futures = cartDocs.map((cartDoc) {
                    final cartData = cartDoc.data();
                    final productId = cartData['product_id'];
                    return FirebaseFirestore.instance.collection('products').doc(productId).get();
                  }).toList();

                  final productSnapshots = await Future.wait(futures);

                  for (int i = 0; i < cartDocs.length; i++) {
                    final cartData = cartDocs[i].data();
                    final productSnapshot = productSnapshots[i];
                    final productData = productSnapshot.data();

                    if (productData != null) {
                      final prod = Product.fromMap(productData);
                      final quantity = prod.pricePoints[cartData['pricePointIndex']].quantity;
                      final currentStock = productData['stock'] ?? 0;

                      if (quantity > currentStock) {
                        hasInsufficientStock = true;
                        insufficientProductName = cartData['productName'] ?? '';
                        remainingQuantity = currentStock;
                        break;
                      }
                    }
                  }

                  if (context.mounted) Navigator.pop(context); // Dismiss loading

                  if (hasInsufficientStock) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('($insufficientProductName)의 남은 수량은 ($remainingQuantity)개 입니다.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                    return;
                  }

                  if (context.mounted) {
                    context.go(Routes.placeOrderScreen);
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context); // Dismiss loading
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('오류가 발생했습니다.')),
                    );
                  }
                }
              },
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF121212),
                foregroundColor: Colors.white,
                minimumSize: Size(70.w, 40.h),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  side: BorderSide(width: 1, color: const Color(0xFF121212)),
                  borderRadius: BorderRadius.circular(11),
                ),
                elevation: 0,
              ),
              child: Text(
                '구매',
                style: TextStyle(
                  color: const Color(0xFFF5F5F5),
                  fontSize: 16.sp,
                  fontFamily: 'NotoSans',
                  fontWeight: FontWeight.w400,
                  height: 1.40.h,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
