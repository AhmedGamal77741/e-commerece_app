import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ImgAndTxt extends StatelessWidget {
  const ImgAndTxt({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset('assets/image_icon.png', width: 17.w, height: 17.h),
        horizontalSpace(3),
        Text('사진 첨부', style: TextStyles.abeezee16px400wP600),
      ],
    );
  }
}
