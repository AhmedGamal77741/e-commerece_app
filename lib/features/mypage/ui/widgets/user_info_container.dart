import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/core/widgets/black_text_button.dart';
import 'package:ecommerece_app/core/widgets/underline_text_filed.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class UserInfoContainer extends StatelessWidget {
  const UserInfoContainer({super.key});

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
            Row(
              children: [
                Text('Nickname', style: TextStyles.abeezee16px400wPblack),
                Spacer(),
                Image.asset(
                  'assets/mypage_avatar.png',
                  height: 55.h,
                  width: 56.w,
                ),
              ],
            ),
            UnderlineTextField(txt: 'pang2chocolate', type: TextInputType.name),
            verticalSpace(20),
            Text('User ID', style: TextStyles.abeezee16px400wPblack),
            UnderlineTextField(
              txt: '+82 10-XXXX-XXXX',
              type: TextInputType.number,
            ),
            verticalSpace(20),
            Text('Password', style: TextStyles.abeezee16px400wPblack),
            Row(
              children: [
                verticalSpace(2),
                Spacer(),
                BlackTextButton(
                  txt: 'complete',
                  func: () {},
                  style: TextStyles.abeezee14px400wW,
                ),
              ],
            ),
            UnderlineTextField(
              txt: 'Alphanumeric combinations',
              type: TextInputType.visiblePassword,
            ),
          ],
        ),
      ),
    );
  }
}
