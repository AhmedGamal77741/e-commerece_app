import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:flutter/material.dart';

class UnderlineTextField extends StatelessWidget {
  final String txt;
  final TextInputType type;
  const UnderlineTextField({super.key, required this.txt, required this.type});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      keyboardType: type,
      maxLines: 1,
      decoration: InputDecoration(
        hintText: txt,
        hintStyle: TextStyles.abeezee14px400wP600,
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: ColorsManager.primary400),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: ColorsManager.primary500, width: 2),
        ),
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: ColorsManager.primary400),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 8),
      ),
    );
  }
}
