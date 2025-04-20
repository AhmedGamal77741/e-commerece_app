import 'package:ecommerece_app/core/helpers/extensions.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class UserOptionsContainer extends StatelessWidget {
  const UserOptionsContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ShapeDecoration(
        color: ColorsManager.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1, color: ColorsManager.primary100),
          borderRadius: BorderRadius.circular(25),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              child: Text(
                'Cancel Membership Subscription',
                style: TextStyles.abeezee16px400wPblack,
              ),
              onTap: () {
                context.pushNamed(Routes.cancelSubscription);
              },
            ),
            Divider(color: ColorsManager.primary100),
            InkWell(
              child: Text(
                'Customer Help Center',
                style: TextStyles.abeezee16px400wPblack,
              ),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
