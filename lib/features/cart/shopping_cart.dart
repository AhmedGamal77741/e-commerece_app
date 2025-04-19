import 'package:ecommerece_app/core/helpers/extensions.dart';
import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/features/review/ui/widgets/text_and_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ShoppingCart extends StatefulWidget {
  const ShoppingCart({super.key});

  @override
  State<ShoppingCart> createState() => _ShoppingCartState();
}

class _ShoppingCartState extends State<ShoppingCart> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/product_image_order.png',
                  width: 90.w,
                  height: 90.h,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pang2Chocolate',
                      style: TextStyles.abeezee14px400wP600,
                    ),
                    verticalSpace(5),
                    Text(
                      'Dark Marshmallow 6 pieces',
                      style: TextStyles.abeezee13px400wPblack,
                    ),
                    verticalSpace(3),

                    Text(
                      'Option : 2 pieces  tom(wed) Arrival Expected',
                      style: TextStyles.abeezee11px400wP600,
                    ),
                    Text('12,000 KRW', style: TextStyles.abeezee13px400wPblack),
                  ],
                ),

                Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.close,
                    color: ColorsManager.primary600,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          width: 428.w,
          height: 50.h,
          decoration: BoxDecoration(color: Colors.white),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Padding(
                padding: EdgeInsets.only(left: 40.w, right: 70.w),
                child: Text(
                  'Total : ',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18.sp,
                    fontFamily: 'ABeeZee',
                    fontWeight: FontWeight.w400,
                    height: 1.40.h,
                  ),
                ),
              ),
              Text(
                '12,000 KRW',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18.sp,
                  fontFamily: 'ABeeZee',
                  fontWeight: FontWeight.w400,
                  height: 1.40.h,
                ),
              ),
              TextButton(
                onPressed: () {
                  context.pushNamed(Routes.placeOrderScreen);
                },
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF121212), // Background color
                  foregroundColor: Colors.white, // Text color
                  minimumSize: Size(102.w, 26.h), // Exact dimensions
                  padding: EdgeInsets.zero, // Remove default padding
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      width: 1,
                      color: const Color(0xFF121212),
                    ), // Border
                    borderRadius: BorderRadius.circular(8), // Corner radius
                  ),
                  elevation: 0, // Remove shadow
                ),
                child: Text(
                  'Place Order',
                  style: TextStyle(
                    color: const Color(0xFFF5F5F5),
                    fontSize: 16.sp,
                    fontFamily: 'ABeeZee',
                    fontWeight: FontWeight.w400,
                    height: 1.40.h,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
