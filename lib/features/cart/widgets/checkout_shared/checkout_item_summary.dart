import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class CheckoutItemSummary extends StatelessWidget {
  final String displayImgUrl;
  final String displayName;
  final int pendingQuantity;
  final int pendingPrice;

  const CheckoutItemSummary({
    super.key,
    required this.displayImgUrl,
    required this.displayName,
    required this.pendingQuantity,
    required this.pendingPrice,
  });

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat('#,###');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '구매목록',
          style: TextStyles.abeezee16px400wPblack.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        verticalSpace(10.h),
        Row(
          children: [
            if (displayImgUrl.isNotEmpty)
              Image.network(
                displayImgUrl,
                width: 80.w,
                height: 80.h,
                fit: BoxFit.cover,
              ),
            horizontalSpace(10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16.sp,
                      fontFamily: 'NotoSans',
                      fontWeight: FontWeight.w400,
                      height: 1.40.h,
                    ),
                  ),
                  verticalSpace(8),
                  Text(
                    '$pendingQuantity 개',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16.sp,
                    fontFamily: 'NotoSans',
                    fontWeight: FontWeight.w400,
                    height: 1.40.h,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '${formatCurrency.format(pendingPrice)} 원',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16.sp,
                    fontFamily: 'NotoSans',
                    fontWeight: FontWeight.w400,
                    height: 1.40.h,
                  ),
                ),
              ],
            ),
            ),
          ],
        ),
      ],
    );
  }
}
