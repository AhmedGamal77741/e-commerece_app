import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/features/cart/slide_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class BuyNowBottomBar extends StatelessWidget {
  final int pendingPrice;
  final bool isProcessing;
  final Future<bool> Function() onValidate;
  final VoidCallback onSlideComplete;

  const BuyNowBottomBar({
    super.key,
    required this.pendingPrice,
    required this.isProcessing,
    required this.onValidate,
    required this.onSlideComplete,
  });

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat('#,###');
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 28.h),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '총 결제 금액 ',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18.sp,
                  fontFamily: 'NotoSans',
                  fontWeight: FontWeight.w700,
                  height: 1.40.h,
                ),
              ),
              Text(
                '${formatCurrency.format(pendingPrice)} 원',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18.sp,
                  fontFamily: 'NotoSans',
                  fontWeight: FontWeight.w700,
                  height: 1.40.h,
                ),
              ),
            ],
          ),
          verticalSpace(8),
          SlideToPayButton(
            isProcessing: isProcessing,
            onValidate: onValidate,
            onSlideComplete: onSlideComplete,
          ),
        ],
      ),
    );
  }
}
