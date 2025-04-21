import 'package:ecommerece_app/core/helpers/extensions.dart';
import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/features/review/ui/widgets/text_and_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OrderHistory extends StatelessWidget {
  const OrderHistory({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                'assets/product_image_order.png',
                width: 113.w,
                height: 113.h,
              ),
              TextAndButtons(txt: '취소', func: () {}),

              Spacer(),
              IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.more_horiz,
                  color: ColorsManager.primary600,
                  size: 18,
                ),
              ),
            ],
          ),
          verticalSpace(10),
          Divider(color: ColorsManager.primary300),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                'assets/product_image_order.png',
                width: 113.w,
                height: 113.h,
              ),
              TextAndButtons(
                txt: '교환 · 환불',
                func: () {
                  context.pushNamed(Routes.exchangeOrRefund);
                },
              ),

              Spacer(),
              IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.more_horiz,
                  color: ColorsManager.primary600,
                  size: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
