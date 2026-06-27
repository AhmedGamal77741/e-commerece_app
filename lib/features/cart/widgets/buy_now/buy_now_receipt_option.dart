import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BuyNowReceiptOption extends StatelessWidget {
  final int selectedOption;
  final VoidCallback onShowBottomSheet;

  const BuyNowReceiptOption({
    super.key,
    required this.selectedOption,
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
                '현금영수증 · 세금계산서',
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
                selectedOption == 1
                    ? '현금 영수증'
                    : selectedOption == 2
                        ? '세금 계산서'
                        : '필요 없음',
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
