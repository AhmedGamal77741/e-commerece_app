import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_entity.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:ecommerece_app/features/home/comments.dart';
import 'package:ecommerece_app/features/home/data/follow_service.dart';
import 'package:ecommerece_app/features/home/data/home_functions.dart';
import 'package:ecommerece_app/features/home/data/post_provider.dart';
import 'package:ecommerece_app/features/home/widgets/post_actions.dart';
import 'package:ecommerece_app/features/home/widgets/show_post_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class PostItem extends StatelessWidget {
  final String postId;
  final bool fromComments;
  final bool showMoreButton;
  const PostItem({
    Key? key,
    required this.postId,
    required this.fromComments,
    this.showMoreButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final postsProvider = Provider.of<PostsProvider>(context, listen: false);
    // Load comments if not already loaded
    if (postsProvider.getComments(postId).isEmpty &&
        !postsProvider.isLoadingComments(postId)) {
      // Start listening to comments for this post
      postsProvider.listenToComments(postId);
    }

    // Use Selector to only rebuild this widget when this specific post changes
    return Selector<PostsProvider, Map<String, dynamic>?>(
      selector: (_, provider) => provider.getPost(postId),
      builder: (context, postData, child) {
        if (postData == null) {
          return SizedBox.shrink(); // Post doesn't exist
        }

        return FutureBuilder<MyUser>(
          future: getUser(postData['userId']),
          builder: (context, snapshot) {
            if (snapshot.hasError || !snapshot.hasData) {
              return _buildPostSkeleton();
            }

            final myuser = snapshot.data!;
            final isMyPost =
                myuser.userId == FirebaseAuth.instance.currentUser?.uid;

            return Column(
              children: [
                if (fromComments)
                  Padding(
                    padding: EdgeInsets.only(
                      top: 20.h,
                      left: 10.w,
                      right: 10.w,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 56.w,
                          height: 55.h,
                          decoration: ShapeDecoration(
                            image: DecorationImage(
                              image: NetworkImage(myuser.url.toString()),
                              fit: BoxFit.cover,
                            ),
                            shape: OvalBorder(),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    myuser.name,
                                    style: TextStyles.abeezee16px400wPblack,
                                  ),
                                  Spacer(),
                                  if (myuser.userId !=
                                      FirebaseAuth.instance.currentUser?.uid)
                                    StreamBuilder<DocumentSnapshot>(
                                      stream:
                                          FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(
                                                FirebaseAuth
                                                    .instance
                                                    .currentUser
                                                    ?.uid,
                                              )
                                              .collection('following')
                                              .doc(myuser.userId)
                                              .snapshots(),
                                      builder: (context, snapshot) {
                                        final isFollowing =
                                            snapshot.hasData &&
                                            snapshot.data!.exists;
                                        return ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                isFollowing
                                                    ? Colors.grey[300]
                                                    : ColorsManager.primary600,
                                            foregroundColor:
                                                isFollowing
                                                    ? Colors.black
                                                    : Colors.white,
                                            minimumSize: Size(47.w, 33.h),
                                            textStyle: TextStyle(
                                              fontSize: 12.sp,
                                              fontFamily: 'NotoSans',
                                              fontWeight: FontWeight.w500,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                          ),
                                          onPressed: () async {
                                            FollowService().toggleFollow(
                                              myuser.userId,
                                            );
                                          },
                                          child: Text(
                                            isFollowing ? '구독 취소' : '구독',
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              fontFamily: 'NotoSans',
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                ],
                              ),
                              StreamBuilder<QuerySnapshot>(
                                stream:
                                    FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(myuser.userId)
                                        .collection('followers')
                                        .snapshots(),
                                builder: (context, subSnap) {
                                  if (subSnap.connectionState ==
                                      ConnectionState.waiting) {
                                    return SizedBox(height: 16.sp);
                                  }
                                  if (subSnap.hasError) {
                                    return Text(
                                      '구독자 오류',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 16.sp,
                                      ),
                                    );
                                  }
                                  final count = subSnap.data?.docs.length ?? 0;
                                  final formatted = count
                                      .toString()
                                      .replaceAllMapped(
                                        RegExp(r'\B(?=(\d{3})+(?!\d))'),
                                        (match) => ',',
                                      );
                                  return Padding(
                                    padding: EdgeInsets.only(top: 2.h),
                                    child: Text(
                                      '구독자 $formatted명',
                                      style: TextStyle(
                                        color: const Color(0xFF787878),
                                        fontSize: 16.sp,
                                        fontFamily: 'NotoSans',
                                        fontWeight: FontWeight.w400,
                                        height: 1.40.h,
                                        letterSpacing: -0.09.w,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              if (postData['text'].toString().isNotEmpty)
                                Padding(
                                  padding: EdgeInsets.only(top: 5.h),
                                  child: Text(
                                    postData['text'],
                                    style: TextStyle(
                                      color: const Color(0xFF343434),
                                      fontSize: 16.sp,
                                      fontFamily: 'NotoSans',
                                      fontWeight: FontWeight.w400,
                                      height: 1.40.h,
                                      letterSpacing: -0.09.w,
                                    ),
                                  ),
                                ),
                              verticalSpace(5),
                              if (postData['imgUrl'].isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    postData['imgUrl'],
                                    width: 200.w,
                                    height: 272.h,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              verticalSpace(5),
                              Row(
                                children: [
                                  PostActions(
                                    postId: postId,
                                    postData: postData,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                if (!fromComments)
                  InkWell(
                    onTap: () {
                      context.push('/${Routes.commentsScreen}?postId=$postId');
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        SizedBox(width: 10.w),
                        Flexible(
                          child: Container(
                            width: 56.w,
                            height: 55.h,
                            decoration: ShapeDecoration(
                              image: DecorationImage(
                                image: NetworkImage(myuser.url.toString()),
                                fit: BoxFit.cover,
                              ),
                              shape: OvalBorder(),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Padding(
                            padding: EdgeInsets.only(right: 10.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  myuser.name,
                                  style: TextStyles.abeezee16px400wPblack,
                                ),
                                if (postData['text'].toString().isNotEmpty)
                                  Padding(
                                    padding: EdgeInsets.only(top: 5.h),
                                    child: Text(
                                      postData['text'],
                                      style: TextStyle(
                                        color: const Color(0xFF343434),
                                        fontSize: 16.sp,
                                        fontFamily: 'NotoSans',
                                        fontWeight: FontWeight.w400,
                                        height: 1.40.h,
                                        letterSpacing: -0.09.w,
                                      ),
                                    ),
                                  ),
                                verticalSpace(5),
                                if (postData['imgUrl'].isNotEmpty)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      postData['imgUrl'],
                                      width: 200.w,
                                      height: 272.h,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                verticalSpace(5),
                                Row(
                                  children: [
                                    PostActions(
                                      postId: postId,
                                      postData: postData,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
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
