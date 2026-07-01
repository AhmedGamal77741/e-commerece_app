import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';

class GuestCommentItem extends ConsumerWidget {
  final Map<String, dynamic> comment;
  const GuestCommentItem({super.key, required this.comment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.only(left: 10.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              width: 40.w,
              height: 40.h,
              decoration: ShapeDecoration(
                image: DecorationImage(
                  image: ResizeImage(CachedNetworkImageProvider(comment['userImage'] ?? ''), width: 120),
                  fit: BoxFit.cover,
                ),
                shape: OvalBorder(),
              ),
            ),
          ),
          horizontalSpace(4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment['userName'] ?? '',
                  style: TextStyles.abeezee16px400wPblack,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  spacing: 4.w,
                  children: [
                    Flexible(
                      fit: FlexFit.loose,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6.r),
                          color: Colors.white,
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 5.w,
                            vertical: 2.h,
                          ),
                          child: Text(
                            comment['text'],
                            style: TextStyle(
                              color: const Color(0xFF343434),
                              fontSize: 16,
                              fontFamily: 'NotoSans',
                              fontWeight: FontWeight.w400,
                              height: 1.40,
                              letterSpacing: -0.09,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 4.w,
                      children: [
                        Icon(
                          Icons.favorite_border,
                          color: Colors.grey,
                          size: 18,
                        ),
                        SizedBox(width: 4),
                        Text(
                          (comment['likes'] ?? 0).toString(),
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            fontFamily: 'NotoSans',
                            fontWeight: FontWeight.w400,
                            height: 1.40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
