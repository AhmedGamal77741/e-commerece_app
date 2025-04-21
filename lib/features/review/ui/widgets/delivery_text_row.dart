import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:flutter/material.dart';

class DeliveryTextRow extends StatelessWidget {
  const DeliveryTextRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '주문\n 완료',
          style: TextStyles.abeezee16px400wPblack,
          textAlign: TextAlign.center,
        ),
        Text(
          '배송 중',
          style: TextStyles.abeezee16px400wPblack,
          textAlign: TextAlign.center,
        ),
        Text(
          '배송\n 완료',
          style: TextStyles.abeezee16px400wP600,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
