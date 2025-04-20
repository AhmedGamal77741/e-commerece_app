import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/core/widgets/black_text_button.dart';
import 'package:ecommerece_app/core/widgets/underline_text_filed.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class UserInfoContainer extends StatelessWidget {
  final passwordController = TextEditingController();
  final emailController = TextEditingController();
  final nameController = TextEditingController();
  UserInfoContainer({super.key});

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
            UnderlineTextField(
              controller: nameController,
              hintText: 'Name',
              obscureText: false,
              keyboardType: TextInputType.name,
              validator: (val) {
                if (val!.isEmpty) {
                  return 'Please fill in this field';
                } else if (val.length > 30) {
                  return 'Name too long';
                }
                return null;
              },
            ),
            verticalSpace(20),
            Text('User ID', style: TextStyles.abeezee16px400wPblack),
            UnderlineTextField(
              controller: nameController,
              hintText: 'Name',
              obscureText: false,
              keyboardType: TextInputType.name,
              validator: (val) {
                if (val!.isEmpty) {
                  return 'Please fill in this field';
                } else if (val.length > 30) {
                  return 'Name too long';
                }
                return null;
              },
            ),
            verticalSpace(20),
            Text('Password', style: TextStyles.abeezee16px400wPblack),
            Row(
              children: [
                Spacer(),
                BlackTextButton(
                  txt: 'complete',
                  func: () {},
                  style: TextStyles.abeezee14px400wW,
                ),
              ],
            ),
            UnderlineTextField(
              controller: nameController,
              hintText: 'Name',
              obscureText: false,
              keyboardType: TextInputType.name,
              validator: (val) {
                if (val!.isEmpty) {
                  return 'Please fill in this field';
                } else if (val.length > 30) {
                  return 'Name too long';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
