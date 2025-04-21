import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/features/review/ui/widgets/delivery_status.dart';
import 'package:ecommerece_app/features/review/ui/widgets/delivery_text_row.dart';
import 'package:ecommerece_app/features/review/ui/widgets/table_container.dart';
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
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
        child: Center(
          child: Column(
            children: [
              Text(
                '예상 도착일 3/27 (목요일)',
                style: TextStyles.abeezee20px400wPblack,
              ),
              verticalSpace(40),
              DeliveryStatus(),
              verticalSpace(10),
              DeliveryTextRow(),
              verticalSpace(30),
              TableContainer(),
            ],
          ),
        ),
      ),
    );
  }
}
