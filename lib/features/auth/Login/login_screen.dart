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
  final passwordController = TextEditingController();
  final emailController = TextEditingController();
  final nameController = TextEditingController();

  LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
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
      ),
    );
  }
}
