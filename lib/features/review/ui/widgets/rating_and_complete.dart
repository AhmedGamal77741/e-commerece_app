import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RatingAndComplete extends StatelessWidget {
  const RatingAndComplete({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        RatingBar(
          itemSize: 35,
          maxRating: 5,
          minRating: 0,
          initialRating: 0,
          allowHalfRating: true,
          ratingWidget: RatingWidget(
            full: Icon(Icons.star, color: ColorsManager.primaryblack),
            half: Icon(Icons.star_half, color: ColorsManager.primaryblack),
            empty: Icon(Icons.star_border, color: ColorsManager.primary300),
          ),
          onRatingUpdate: (rating) {
            print("Rating is: $rating");
          },
        ),
        Spacer(),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            backgroundColor: ColorsManager.primaryblack,
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: Text('Compelete', style: TextStyles.abeezee14px400wW),
        ),
      ],
    );
  }
}
