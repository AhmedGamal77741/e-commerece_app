import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:flutter/material.dart';

class WideTextButton extends StatelessWidget {
  final String txt;
  final VoidCallback func;

  const WideTextButton({super.key, required this.txt, required this.func});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: func,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(ColorsManager.primary500),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: WidgetStateProperty.all(Size(double.infinity, 52)),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      child: Text(txt, style: TextStyles.abeezee23px400wW),
    );
  }
}
