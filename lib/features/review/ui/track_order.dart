import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TrackOrder extends StatelessWidget {
  const TrackOrder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ColorsManager.white,
        title: Text('Track Order', style: TextStyles.abeezee16px400wPblack),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        child: Center(
          child: Column(
            children: [
              Text(
                'Estimated Arrival 3/27 (Thursday)',
                style: TextStyles.abeezee20px400wPblack,
              ),
              verticalSpace(40),
              Row(
                children: [
                  Container(
                    width: 90.w,
                    height: 110.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: ColorsManager.primary300,
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
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
