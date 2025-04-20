import 'package:ecommerece_app/core/helpers/extensions.dart';
import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/core/widgets/underline_text_filed.dart';
import 'package:ecommerece_app/core/widgets/wide_text_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 20.h),
      child: Column(
        children: [
          Container(
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
                  verticalSpace(20),
                  Text('User ID', style: TextStyles.abeezee16px400wPblack),
                  UnderlineTextField(
                    txt: 'phone number',
                    type: TextInputType.number,
                  ),
                  verticalSpace(20),
                  Text('Password', style: TextStyles.abeezee16px400wPblack),
                  UnderlineTextField(
                    txt: 'Alphanumeric combinations',
                    type: TextInputType.visiblePassword,
                  ),
                ],
              ),
            ),
          ),
          verticalSpace(30),
          WideTextButton(
            txt: 'Sign in',
            func: () {
              context.pushReplacementNamed(Routes.navBar);
            },
            color: ColorsManager.primaryblack,
            txtColor: ColorsManager.white,
          ),
        ],
      ),
    );
  }
}
