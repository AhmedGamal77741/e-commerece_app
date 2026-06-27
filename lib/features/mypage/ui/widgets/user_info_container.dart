import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/core/widgets/underline_text_filed.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class UserInfoContainer extends StatelessWidget {
  final MyUser currentUser;
  final TextEditingController passwordController;
  final TextEditingController phoneController;

  const UserInfoContainer({
    super.key,
    required this.currentUser,
    required this.passwordController,
    required this.phoneController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ShapeDecoration(
        color: ColorsManager.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1.w, color: ColorsManager.primary100),
          borderRadius: BorderRadius.circular(25.r),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '아이디',
              style: TextStyles.abeezee16px400wPblack.copyWith(fontSize: 16.sp),
            ),
            SizedBox(height: 5.h),
            IgnorePointer(
              ignoring: true,
              child: UnderlineTextField(
                controller:
                    TextEditingController(), // Dummy controller since it's ignoring pointer
                hintText: currentUser.email,
                obscureText: false,
                keyboardType: TextInputType.emailAddress,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              '전화번호',
              style: TextStyles.abeezee16px400wPblack.copyWith(fontSize: 16.sp),
            ),
            SizedBox(height: 5.h),
            UnderlineTextField(
              controller: phoneController,
              hintText:
                  (currentUser.phoneNumber != null &&
                          currentUser.phoneNumber!.isNotEmpty)
                      ? currentUser.phoneNumber!
                      : '지정되지 않음',
              obscureText: false,
              keyboardType: TextInputType.phone,
              validator: (val) {
                if (val!.isEmpty) return null;
                final koreanReg = RegExp(
                  r'^01([0|1|6|7|8|9])-?([0-9]{3,4})-?([0-9]{4})$',
                );
                if (!koreanReg.hasMatch(val)) {
                  return '유효한 한국 전화번호를 입력하세요';
                }
                return null;
              },
            ),
            SizedBox(height: 20.h),
            Text(
              '비밀번호',
              style: TextStyles.abeezee16px400wPblack.copyWith(fontSize: 16.sp),
            ),
            SizedBox(height: 5.h),
            _PasswordFieldWithVisibility(controller: passwordController),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}

class _PasswordFieldWithVisibility extends StatefulWidget {
  final TextEditingController controller;
  const _PasswordFieldWithVisibility({required this.controller});

  @override
  State<_PasswordFieldWithVisibility> createState() =>
      _PasswordFieldWithVisibilityState();
}

class _PasswordFieldWithVisibilityState
    extends State<_PasswordFieldWithVisibility> {
  bool obscure = true;
  IconData icon = Icons.visibility_off;

  @override
  Widget build(BuildContext context) {
    return UnderlineTextField(
      controller: widget.controller,
      hintText: '영문,숫자 조합',
      obscureText: obscure,
      keyboardType: TextInputType.visiblePassword,
      validator: (val) {
        if (val!.isEmpty) return null;
        if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d).{8,}$').hasMatch(val)) {
          return '유효한 비밀번호를 입력해 주세요';
        }
        return null;
      },
      suffixIcon: IconButton(
        onPressed: () {
          setState(() {
            obscure = !obscure;
            icon = obscure ? Icons.visibility_off : Icons.visibility;
          });
        },
        icon: Icon(icon),
      ),
    );
  }
}
