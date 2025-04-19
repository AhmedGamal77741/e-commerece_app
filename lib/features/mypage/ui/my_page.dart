import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/features/mypage/ui/widgets/user_info_container.dart';
import 'package:ecommerece_app/features/mypage/ui/widgets/user_options_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MyPage extends StatelessWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 20.h),
        child: Column(
          children: [
            UserInfoContainer(),
            verticalSpace(30),
            UserOptionsContainer(),
          ],
        ),
      ),
    );
  }
}
