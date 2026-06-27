import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:ecommerece_app/features/home/widgets/post_actions.dart';
import 'package:ecommerece_app/core/helpers/spacing.dart';

class PostActionButtons extends StatelessWidget {
  final String postId;
  final Map<String, dynamic> postData;

  const PostActionButtons({
    super.key,
    required this.postId,
    required this.postData,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        PostActions(
          postId: postId,
          postData: postData,
        ),
        horizontalSpace(4),
        Expanded(
          child: Container(
            height: 1.h,
            color: Colors.grey[600],
          ),
        ),
        InkWell(
          onTap: () => context.pop(),
          child: const Icon(Icons.close),
        ),
      ],
    );
  }
}
