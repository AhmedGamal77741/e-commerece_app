import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:flutter/material.dart';

class RepField extends StatelessWidget {
  const RepField({super.key});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      maxLines: 8,
      minLines: 7,
      keyboardType: TextInputType.multiline,
      decoration: InputDecoration(
        hintText: "리뷰 보내기 (3일 남음)",
        hintStyle: TextStyles.abeezee16px400wP600,
        contentPadding: EdgeInsets.all(12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: ColorsManager.primary400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: ColorsManager.primary400),
        ),
      ),
    );
  }
}
