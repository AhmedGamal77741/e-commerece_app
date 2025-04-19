import 'package:ecommerece_app/core/helpers/extensions.dart';
import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Dessert extends StatefulWidget {
  const Dessert({super.key});

  @override
  State<Dessert> createState() => _DessertState();
}

class _DessertState extends State<Dessert> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.pushNamed(Routes.shopSearchScreen);
        },
        child: Icon(Icons.search, color: Colors.white),
        elevation: 0,
        backgroundColor: Colors.black,
        shape: CircleBorder(), // Explicit circular shape
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        child: InkWell(
          onTap: () {
            context.pushNamed(Routes.itemDetailsScreen);
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                'assets/product_image_order.png',
                width: 105.w,
                height: 105.h,
              ),
              Padding(
                padding: EdgeInsets.only(left: 10.w),
                child: Column(
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
                    Text('12,000 KRW', style: TextStyles.abeezee13px400wPblack),

                    Text(
                      'Tomorrow(Wed) Expected - Free Shipping',
                      style: TextStyles.abeezee11px400wP600,
                    ),
                    Row(
                      children: [
                        RatingBar(
                          ignoreGestures: true,
                          itemSize: 20.sp,
                          maxRating: 5,
                          minRating: 0,
                          initialRating: 3.5,
                          allowHalfRating: true,
                          ratingWidget: RatingWidget(
                            full: Icon(
                              Icons.star,
                              color: ColorsManager.primaryblack,
                            ),
                            half: Icon(
                              Icons.star_half,
                              color: ColorsManager.primaryblack,
                            ),
                            empty: Icon(
                              Icons.star_border,
                              color: ColorsManager.primary300,
                            ),
                          ),
                          onRatingUpdate: (rating) {
                            print("Rating is: $rating");
                          },
                        ),
                        Text("(140)", style: TextStyles.abeezee14px400wP600),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
