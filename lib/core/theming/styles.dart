import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TextStyles {
  static TextStyle _textStyle({
    required double fontSize,
    required FontWeight fontWeight,
    required color,
    double letterSpacing = 0,
    String fontFamily = 'ABeeZee',
  }) {
    return TextStyle(
      fontSize: fontSize.sp,
      decoration: TextDecoration.none,
      fontFamily: fontFamily,
      fontStyle: FontStyle.normal,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  static final TextStyle abeezee14px400wP600 = _textStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: ColorsManager.primary600,
  );
  static final TextStyle abeezee16px400wPblack = _textStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: ColorsManager.primaryblack,
  );
  static final TextStyle abeezee14px400wW = _textStyle(
    color: ColorsManager.white,
    fontSize: 14.sp,
    fontWeight: FontWeight.w400,
  );
  static final TextStyle abeezee16px400wP600 = _textStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: ColorsManager.primary600,
  );
  static final TextStyle abeezee11px400wP600 = _textStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: ColorsManager.primary600,
  );
  static final TextStyle abeezee13px400wPblack = _textStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: ColorsManager.primaryblack,
  );
  static final TextStyle abeezee12px400wW = _textStyle(
    color: ColorsManager.white,
    fontSize: 12.sp,
    fontWeight: FontWeight.w400,
  );
  static final TextStyle abeezee20px400wPblack = _textStyle(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    color: ColorsManager.primaryblack,
  );
}
