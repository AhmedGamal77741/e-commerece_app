import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/core/widgets/black_text_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

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
        BlackTextButton(
          txt: '완료하다',
          func: () {},
          style: TextStyles.abeezee14px400wW,
        ),
      ],
    );
  }
}
