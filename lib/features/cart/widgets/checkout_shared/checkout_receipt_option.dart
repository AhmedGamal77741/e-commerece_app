import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CheckoutReceiptOption extends StatelessWidget {
  final VoidCallback onShowBottomSheet;

  const CheckoutReceiptOption({
    super.key,
    required this.onShowBottomSheet,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '현금영수증 수령 이메일',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16.sp,
                  fontFamily: 'NotoSans',
                  fontWeight: FontWeight.w800,
                  height: 1.40.h,
                ),
              ),
              verticalSpace(5),
              Text(
                '현금영수증 발급',
                style: TextStyle(
                  fontSize: 15.sp,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onShowBottomSheet,
          icon: Icon(
            Icons.arrow_forward_ios,
            size: 30.r,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
