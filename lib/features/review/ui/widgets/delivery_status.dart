import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DeliveryStatus extends StatelessWidget {
  final String orderStatus;
  const DeliveryStatus({super.key, required this.orderStatus});

  @override
  Widget build(BuildContext context) {
    return orderStatus == 'OUT_FOR_DELIVERY'
        ? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100.w,
              height: 100.h,
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
              width: 50.w,
              height: 15.h,
              decoration: BoxDecoration(color: ColorsManager.primaryblack),
            ),
            Container(
              width: 100.w,
              height: 100.h,
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
              width: 50.w,
              height: 15.h,
              decoration: BoxDecoration(color: ColorsManager.primary300),
            ),
            Container(
              width: 100.w,
              height: 100.h,
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
        )
        : orderStatus == 'DELIVERED'
        ? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100.w,
              height: 100.h,
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
              width: 50.w,
              height: 15.h,
              decoration: BoxDecoration(color: ColorsManager.primaryblack),
            ),
            Container(
              width: 100.w,
              height: 100.h,
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
              width: 50.w,
              height: 15.h,
              decoration: BoxDecoration(color: ColorsManager.primaryblack),
            ),
            Container(
              width: 100.w,
              height: 100.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: ColorsManager.primaryblack,
              ),
              child: Icon(
                Icons.checklist_rounded,
                size: 50,
                color: ColorsManager.white,
              ),
            ),
          ],
        )
        : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100.w,
              height: 100.h,
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
              width: 50.w,
              height: 15.h,
              decoration: BoxDecoration(color: ColorsManager.primary300),
            ),
            Container(
              width: 100.w,
              height: 100.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: ColorsManager.primary300,
              ),
              child: Icon(
                Icons.local_shipping,
                size: 50,
                color: ColorsManager.white,
              ),
            ),
            Container(
              width: 50.w,
              height: 15.h,
              decoration: BoxDecoration(color: ColorsManager.primary300),
            ),
            Container(
              width: 100.w,
              height: 100.h,
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
