import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/features/auth/domain/auth_controller.dart';
import 'package:ecommerece_app/features/cart/domain/cart_controller.dart';
import 'package:ecommerece_app/features/cart/domain/checkout_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class CheckoutMultiItemSummary extends ConsumerWidget {
  final String uid;

  const CheckoutMultiItemSummary({super.key, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatCurrency = NumberFormat('#,###');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '구매목록',
          style: TextStyles.abeezee16px400wPblack.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        verticalSpace(10.h),
        StreamBuilder(
          stream: ref.read(checkoutControllerProvider.notifier).getUserCartStream(uid),
          builder: (context, cartSnapshot) {
            if (cartSnapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox.shrink();
            }
            if (!cartSnapshot.hasData || cartSnapshot.data!.docs.isEmpty) {
              return const Text('장바구니가 비어 있습니다.');
            }
            final cartDocs = cartSnapshot.data!.docs;
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (_, index) =>
                  index == cartDocs.length - 1 ? const SizedBox.shrink() : verticalSpace(10),
              itemCount: cartDocs.length,
              itemBuilder: (ctx, index) {
                final cartData = cartDocs[index].data();
                final productId = cartData['product_id'];
                return FutureBuilder<DocumentSnapshot>(
                  future: ref
                      .read(checkoutControllerProvider.notifier)
                      .getProductFuture(productId as String),
                  builder: (context, productSnapshot) {
                    if (!productSnapshot.hasData) {
                      return const ListTile(
                        title: Text('로딩 중...'),
                      );
                    }
                    final productData =
                        productSnapshot.data!.data() as Map<String, dynamic>;
                    return Row(
                      children: [
                        Image.network(
                          productData['imgUrl'] ?? '',
                          width: 80.w,
                          height: 80.h,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => SizedBox(
                            width: 80.w,
                            height: 80.h,
                            child: const Icon(Icons.image_not_supported),
                          ),
                        ),
                        horizontalSpace(10),
                        Flexible(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${productData['productName']}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16.sp,
                                  fontFamily: 'NotoSans',
                                  fontWeight: FontWeight.w400,
                                  height: 1.40.h,
                                ),
                              ),
                              verticalSpace(8),
                              Consumer(
                                builder: (context, ref, child) {
                                  final productAsync = ref.watch(
                                      productStreamProvider(cartData['product_id']));
                                  final quantity = productAsync.value?.pricePoints[cartData['pricePointIndex']].quantity ?? 0;
                                  return Text(
                                    '$quantity 개',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16.sp,
                                      fontFamily: 'NotoSans',
                                      fontWeight: FontWeight.w400,
                                      height: 1.40.h,
                                    ),
                                  );
                                },
                              ),
                              SizedBox(height: 8.h),
                              Consumer(
                                builder: (context, ref, child) {
                                  final productAsync = ref.watch(
                                      productStreamProvider(cartData['product_id']));
                                  final isUserSub = ref.watch(isSubscribedProvider).value ?? false;
                                  double price = productAsync.value?.pricePoints[cartData['pricePointIndex']].price.toDouble() ?? 0.0;
                                  if (!isUserSub) {
                                    price = price / 0.8;
                                  }
                                  return Text(
                                    '${formatCurrency.format(price)} 원',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16.sp,
                                      fontFamily: 'NotoSans',
                                      fontWeight: FontWeight.w400,
                                      height: 1.40.h,
                                    ),
                                  );
                                },
                              ),
                            ],
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
    );
  }
}
