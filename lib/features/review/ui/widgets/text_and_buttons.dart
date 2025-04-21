import 'package:ecommerece_app/core/helpers/extensions.dart';
import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/core/widgets/black_text_button.dart';
import 'package:flutter/material.dart';

class TextAndButtons extends StatelessWidget {
  final String txt;
  final VoidCallback func;
  const TextAndButtons({super.key, required this.txt, required this.func});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pang2Chocolate', style: TextStyles.abeezee11px400wP600),
        Text('다크 마시멜로 6개', style: TextStyles.abeezee13px400wPblack),
        Text('옵션: 2개 내일(수) 도착 예상', style: TextStyles.abeezee11px400wP600),
        Text('12,000 KRW', style: TextStyles.abeezee13px400wPblack),
        Row(
          children: [
            BlackTextButton(
              txt: '주문 추적',
              style: TextStyles.abeezee12px400wW,
              func: () {
                context.pushNamed(Routes.trackorder);
              },
            ),
            horizontalSpace(5),
            BlackTextButton(
              txt: txt,
              style: TextStyles.abeezee12px400wW,
              func: func,
            ),
          ],
        ),
      ],
    );
  }
}
