import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_entity.dart';
import 'package:ecommerece_app/features/home/data/home_functions.dart';
import 'package:ecommerece_app/features/home/widgets/post_actions.dart';
import 'package:ecommerece_app/features/home/widgets/show_post_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

Widget buildPostItem(DocumentSnapshot post, BuildContext context) {
  final data = post.data() as Map<String, dynamic>;
  print(data['userId']);
  return FutureBuilder<MyUserEntity>(
    future: getUser(data['userId']),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return _buildPostSkeleton(); // Return a loading placeholder
      }

      if (snapshot.hasError || !snapshot.hasData) {
        return _buildErrorPost(); // Return an error widget
      }

      final myuser = snapshot.data!; // Now you have the user data
      print(myuser.name);
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Avatar
              Flexible(
                child: Padding(
                  padding: EdgeInsets.only(top: 20.h),
                  child: Container(
                    width: 56.w,
                    height: 55.h,
                    decoration: ShapeDecoration(
                      image: DecorationImage(
                        image: NetworkImage(myuser.url),
                        fit: BoxFit.cover,
                      ),
                      shape: OvalBorder(),
                    ),
                  ),
                ),
              ),

              // Post Content
              Expanded(
                flex: 4,
                child: Padding(
                  padding: EdgeInsets.only(right: 10.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with menu
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            myuser.name,
                            style: TextStyles.abeezee16px400wPblack,
                          ),
                          IconButton(
                            icon: Icon(Icons.more_horiz),
                            onPressed:
                                () => showPostMenu(context /* post.id */),
                          ),
                        ],
                      ),

                      // Post Text
                      if (data['text'].toString().isNotEmpty)
                        Text(
                          data['text'],
                          style: TextStyle(
                            color: const Color(0xFF343434),
                            fontSize: 16.sp,
                            fontFamily: 'ABeeZee',
                            fontWeight: FontWeight.w400,
                            height: 1.40.h,
                            letterSpacing: -0.09.w,
                          ),
                        ),
                      verticalSpace(5),
                      // Post Image
                      if (data['imgUrl'].isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            data['imgUrl'],
                            width: 200.w,
                            height: 272.h,
                            fit: BoxFit.cover,
                          ),
                        ),
                      verticalSpace(5),
                      // Like/Comment Buttons
                      buildPostActions(post),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}

Widget _buildPostSkeleton() {
  return Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: Container(
      height: 100,
      margin: EdgeInsets.all(8),
      color: Colors.white,
    ),
  );
}

Widget _buildErrorPost() {
  return Container(
    padding: EdgeInsets.all(16),
    child: Text('Failed to load user', style: TextStyle(color: Colors.red)),
  );
}
