import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ExchangeBody extends StatelessWidget {
  const ExchangeBody({super.key});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 25.h),
            child: Text('Reason', style: TextStyles.abeezee16px400wPblack),
          ),
          Divider(color: ColorsManager.primary100),
          TextFormField(
            maxLines: 6,
            minLines: 4,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(
              hintText: "Enter",
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
    );
  }
}
