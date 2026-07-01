import 'package:ecommerece_app/core/helpers/basetime.dart';
import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/core/widgets/black_text_button.dart';
import 'package:go_router/go_router.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/features/review/ui/widgets/text_and_buttons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ecommerece_app/core/widgets/safe_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A single order row displaying product image, details, and action buttons.
class OrderItemCard extends StatelessWidget {
  const OrderItemCard({
    super.key,
    required this.orderData,
    required this.product,
    required this.user,
    required this.onDelete,
  });

  final Map<String, dynamic> orderData;
  final Map<String, dynamic> product;
  final User user;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SafeNetworkImage(
            url: product['imgUrl'] ?? '',
            width: 120.w,
            height: 120.h,
            fit: BoxFit.cover,
            errorWidget: Container(
              width: 120.w,
              height: 120.h,
              color: Colors.grey.shade200,
              child: const Icon(
                Icons.image_not_supported,
                color: Colors.grey,
              ),
            ),
          ),
        ),
        horizontalSpace(10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextAndButtons(
                sellerName: product['sellerName'] ?? '',
                productName: product['productName'] ?? '',
                qunatity: orderData['quantity'].toString(),
                orderPrice: orderData['totalPrice'],
                baselineTime: product['baselineTime'],
                meridiem: product['meridiem'],
              ),
              Row(
                children: [
                  BlackTextButton(
                    txt: '배송조회',
                    style: TextStyles.abeezee14px400wW,
                    func: () async {
                      final arrivalDate = await getArrivalDay2(
                        product['meridiem'],
                        product['baselineTime'],
                      );
                      if (!context.mounted) return;
                      context.pushNamed(
                        Routes.trackorder,
                        extra: {
                          'order': orderData,
                          'arrivalDate': arrivalDate,
                        },
                      );
                    },
                  ),
                  horizontalSpace(5),
                  if (orderData['confirmed'] == true) ...[
                    if (orderData['isRequested'] == true)
                      BlackTextButton(
                        txt: '교환 · 반품 신청',
                        style: TextStyles.abeezee14px400wW.copyWith(
                          decoration: TextDecoration.lineThrough,
                          decorationColor: Colors.red,
                          decorationThickness: 2,
                        ),
                        func: () {},
                      )
                    else
                      BlackTextButton(
                        txt: '교환 · 반품 신청',
                        style: TextStyles.abeezee14px400wW,
                        func: () {
                          context.pushNamed(
                            Routes.exchangeOrRefund,
                            extra: {
                              'userId': user.uid,
                              'orderId': orderData['orderId'],
                            },
                          );
                        },
                      ),
                  ] else
                    BlackTextButton(
                      txt: '주문취소',
                      style: TextStyles.abeezee14px400wW,
                      func: onDelete,
                    ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: Icon(
            Icons.more_horiz,
            color: ColorsManager.primary600,
            size: 18,
          ),
        ),
      ],
    );
  }
}
