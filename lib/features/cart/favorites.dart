import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CartFavorites extends StatefulWidget {
  const CartFavorites({super.key});

  @override
  State<CartFavorites> createState() => _CartFavoritesState();
}

class _CartFavoritesState extends State<CartFavorites> {
  @override
  Widget build(BuildContext context) {
    return Padding(
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
              Text('Pang2Chocolate', style: TextStyles.abeezee14px400wP600),
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
            icon: Icon(Icons.close, color: ColorsManager.primary600, size: 18),
          ),
        ],
      ),
    );
  }
}
