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
          'Order\n Complete',
          style: TextStyles.abeezee16px400wPblack,
          textAlign: TextAlign.center,
        ),
        Text(
          'On Delivery',
          style: TextStyles.abeezee16px400wPblack,
          textAlign: TextAlign.center,
        ),
        Text(
          'Delievery\nCompelete',
          style: TextStyles.abeezee16px400wP600,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
