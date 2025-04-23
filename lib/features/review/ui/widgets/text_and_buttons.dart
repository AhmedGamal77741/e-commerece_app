import 'package:ecommerece_app/core/helpers/extensions.dart';
import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/core/widgets/black_text_button.dart';
import 'package:flutter/material.dart';

class TextAndButtons extends StatelessWidget {
  final String orderId;
  final String orderDate;
  final String orderStatus;
  final String orderPrice;

  const TextAndButtons({
    super.key,

    required this.orderId,
    required this.orderDate,
    required this.orderStatus,
    required this.orderPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(orderId, style: TextStyles.abeezee11px400wP600),
        Text(orderDate, style: TextStyles.abeezee13px400wPblack),
        Text(orderStatus, style: TextStyles.abeezee11px400wP600),
        Text('$orderPrice 원', style: TextStyles.abeezee13px400wPblack),
        Row(
          children: [
            BlackTextButton(
              txt: '배송조회',
              style: TextStyles.abeezee12px400wW,
              func: () {},
            ),
            horizontalSpace(5),
            BlackTextButton(
              txt: '주문취소',
              style: TextStyles.abeezee12px400wW,
              func: () {},
            ),
          ],
        ),
      ],
    );
  }
}
