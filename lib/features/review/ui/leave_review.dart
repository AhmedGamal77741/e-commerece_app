import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/features/review/ui/widgets/avatar_and_title.dart';
import 'package:ecommerece_app/features/review/ui/widgets/rating_and_complete.dart';
import 'package:ecommerece_app/features/review/ui/widgets/rep_filed.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LeaveReview extends StatelessWidget {
  const LeaveReview({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      child: SingleChildScrollView(
        child: Column(
          children: [
            AvatarAndTitle(),
            verticalSpace(10),
            RatingAndComplete(),
            verticalSpace(10),
            RepField(),
            verticalSpace(10),
            Row(
              children: [
                Image.asset('assets/image_icon.png', width: 17.w, height: 17.h),
                horizontalSpace(3),
                Text('사진 첨부', style: TextStyles.abeezee16px400wP600),
              ],
            ),

            Divider(color: ColorsManager.primary600),
          ],
        ),
      ),
    );
  }
}
