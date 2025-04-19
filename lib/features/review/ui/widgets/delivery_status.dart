import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DeliveryStatus extends StatelessWidget {
  const DeliveryStatus({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 90.w,
          height: 110.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: ColorsManager.primaryblack,
          ),
          child: Icon(
            Icons.dashboard_customize_rounded,
            size: 50,
            color: ColorsManager.white,
          ),
        ),
        Container(
          width: 60.w,
          height: 20.h,
          decoration: BoxDecoration(color: ColorsManager.primaryblack),
        ),
        Container(
          width: 90.w,
          height: 110.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: ColorsManager.primaryblack,
          ),
          child: Icon(
            Icons.local_shipping,
            size: 50,
            color: ColorsManager.white,
          ),
        ),
        Container(
          width: 60.w,
          height: 20.h,
          decoration: BoxDecoration(color: ColorsManager.primary300),
        ),
        Container(
          width: 90.w,
          height: 110.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: ColorsManager.primary300,
          ),
          child: Icon(
            Icons.checklist_rounded,
            size: 50,
            color: ColorsManager.white,
          ),
        ),
      ],
    );
  }
}
