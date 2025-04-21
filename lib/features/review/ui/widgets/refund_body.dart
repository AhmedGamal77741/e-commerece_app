import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/core/widgets/underline_text_filed.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RefundBody extends StatelessWidget {
  final passwordController = TextEditingController();
  final emailController = TextEditingController();
  final nameController = TextEditingController();
  RefundBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: ShapeDecoration(
            color: ColorsManager.white,
            shape: RoundedRectangleBorder(
              side: BorderSide(width: 1, color: ColorsManager.primary100),
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 25.h),
                child: Text('이유', style: TextStyles.abeezee16px400wPblack),
              ),
              Divider(color: ColorsManager.primary100),
              TextFormField(
                maxLines: 6,
                minLines: 4,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  hintText: "입장하다",
                  hintStyle: TextStyles.abeezee16px400wP600,
                  contentPadding: EdgeInsets.all(12),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                ),
              ),
            ],
          ),
        ),
        verticalSpace(30),
        Container(
          decoration: ShapeDecoration(
            color: ColorsManager.white,
            shape: RoundedRectangleBorder(
              side: BorderSide(width: 1, color: ColorsManager.primary100),
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('계좌 번호', style: TextStyles.abeezee16px400wPblack),
                UnderlineTextField(
                  controller: nameController,
                  hintText: '이름',
                  obscureText: false,
                  keyboardType: TextInputType.name,
                  validator: (val) {
                    if (val!.isEmpty) {
                      return '이 필드를 작성해 주세요';
                    } else if (val.length > 30) {
                      return '이름이 너무 깁니다';
                    }
                    return null;
                  },
                ),
                verticalSpace(15),
                Text('계좌 번호', style: TextStyles.abeezee16px400wPblack),
                UnderlineTextField(
                  controller: nameController,
                  hintText: '이름',
                  obscureText: false,
                  keyboardType: TextInputType.name,
                  validator: (val) {
                    if (val!.isEmpty) {
                      return '이 필드를 작성해 주세요';
                    } else if (val.length > 30) {
                      return '이름이 너무 깁니다';
                    }
                    return null;
                  },
                ),
                verticalSpace(15),
                Text('계좌 소유자', style: TextStyles.abeezee16px400wPblack),
                UnderlineTextField(
                  controller: nameController,
                  hintText: '이름',
                  obscureText: false,
                  keyboardType: TextInputType.name,
                  validator: (val) {
                    if (val!.isEmpty) {
                      return '이 필드를 작성해 주세요';
                    } else if (val.length > 30) {
                      return '이름이 너무 깁니다';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
