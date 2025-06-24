import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_entity.dart';
import 'package:ecommerece_app/features/home/comments.dart';
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
    // Use Selector to only rebuild this widget when this specific post changes
    return Selector<PostsProvider, Map<String, dynamic>?>(
      selector: (_, provider) => provider.getPost(postId),
      builder: (context, postData, child) {
        if (postData == null) {
          return SizedBox.shrink(); // Post doesn't exist
        }

        return FutureBuilder<MyUserEntity>(
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
                              image: NetworkImage(myuser.url.toString()),
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
                      child: InkWell(
                        onTap: () {
                          if (!fromComments) {
                            context.push(
                              '/${Routes.commentsScreen}?postId=$postId',
                            );
                          }
                        },
                        child: Padding(
                          padding: EdgeInsets.only(right: 10.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header with menu
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    myuser.name,
                                    style: TextStyles.abeezee16px400wPblack,
                                  ),
                                  if (showMoreButton)
                                    Builder(
                                      builder:
                                          (parentContext) =>
                                              isMyPost
                                                  ? IconButton(
                                                    icon: Icon(
                                                      Icons.more_horiz,
                                                    ),
                                                    onPressed: () {
                                                      showModalBottomSheet(
                                                        context: parentContext,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.vertical(
                                                                top:
                                                                    Radius.circular(
                                                                      16,
                                                                    ),
                                                              ),
                                                        ),
                                                        backgroundColor:
                                                            Colors.white,
                                                        builder:
                                                            (
                                                              context,
                                                            ) => SafeArea(
                                                              child: Padding(
                                                                padding:
                                                                    EdgeInsets.symmetric(
                                                                      vertical:
                                                                          12.h,
                                                                      horizontal:
                                                                          8.w,
                                                                    ),
                                                                child: Column(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  children: [
                                                                    ListTile(
                                                                      leading: Icon(
                                                                        Icons
                                                                            .edit,
                                                                        color:
                                                                            Colors.black87,
                                                                      ),
                                                                      title: Text(
                                                                        '수정',
                                                                        style: TextStyle(
                                                                          fontSize:
                                                                              16.sp,
                                                                          fontWeight:
                                                                              FontWeight.w500,
                                                                        ),
                                                                      ),
                                                                      onTap: () async {
                                                                        Navigator.pop(
                                                                          context,
                                                                        );
                                                                        final controller = TextEditingController(
                                                                          text:
                                                                              postData['text'] ??
                                                                              '',
                                                                        );
                                                                        final result = await showDialog<
                                                                          bool
                                                                        >(
                                                                          context:
                                                                              parentContext,
                                                                          builder:
                                                                              (
                                                                                context,
                                                                              ) => AlertDialog(
                                                                                title: Text(
                                                                                  '게시글 수정',
                                                                                ),
                                                                                content: TextField(
                                                                                  controller:
                                                                                      controller,
                                                                                  maxLines:
                                                                                      5,
                                                                                  decoration: InputDecoration(
                                                                                    labelText:
                                                                                        '게시글을 수정하세요',
                                                                                    border:
                                                                                        OutlineInputBorder(),
                                                                                  ),
                                                                                ),
                                                                                actions: [
                                                                                  TextButton(
                                                                                    onPressed:
                                                                                        () => Navigator.pop(
                                                                                          context,
                                                                                          false,
                                                                                        ),
                                                                                    child: Text(
                                                                                      '취소',
                                                                                      style: TextStyle(
                                                                                        color:
                                                                                            Colors.black,
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                  TextButton(
                                                                                    onPressed: () async {
                                                                                      final newText =
                                                                                          controller.text.trim();
                                                                                      if (newText.isNotEmpty) {
                                                                                        await FirebaseFirestore.instance
                                                                                            .collection(
                                                                                              'posts',
                                                                                            )
                                                                                            .doc(
                                                                                              postId,
                                                                                            )
                                                                                            .update(
                                                                                              {
                                                                                                'text':
                                                                                                    newText,
                                                                                              },
                                                                                            );
                                                                                      }
                                                                                      Navigator.pop(
                                                                                        context,
                                                                                        true,
                                                                                      );
                                                                                    },
                                                                                    child: Text(
                                                                                      '수정',
                                                                                      style: TextStyle(
                                                                                        color:
                                                                                            Colors.black,
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                        );
                                                                        if (result ==
                                                                            true) {
                                                                          ScaffoldMessenger.of(
                                                                            parentContext,
                                                                          ).showSnackBar(
                                                                            SnackBar(
                                                                              content: Text(
                                                                                '게시글이 수정되었습니다.',
                                                                              ),
                                                                            ),
                                                                          );
                                                                        }
                                                                      },
                                                                    ),
                                                                    Divider(
                                                                      height: 1,
                                                                    ),
                                                                    ListTile(
                                                                      leading: Icon(
                                                                        Icons
                                                                            .delete,
                                                                        color:
                                                                            Colors.red,
                                                                      ),
                                                                      title: Text(
                                                                        '삭제',
                                                                        style: TextStyle(
                                                                          fontSize:
                                                                              16.sp,
                                                                          fontWeight:
                                                                              FontWeight.w500,
                                                                          color:
                                                                              Colors.red,
                                                                        ),
                                                                      ),
                                                                      onTap: () async {
                                                                        Navigator.pop(
                                                                          context,
                                                                        );
                                                                        final confirm = await showDialog<
                                                                          bool
                                                                        >(
                                                                          context:
                                                                              parentContext,
                                                                          builder:
                                                                              (
                                                                                context,
                                                                              ) => AlertDialog(
                                                                                title: Text(
                                                                                  '게시글 삭제',
                                                                                ),
                                                                                content: Text(
                                                                                  '정말로 이 게시글을 삭제하시겠습니까?',
                                                                                ),
                                                                                actions: [
                                                                                  TextButton(
                                                                                    onPressed:
                                                                                        () => Navigator.pop(
                                                                                          context,
                                                                                          false,
                                                                                        ),
                                                                                    child: Text(
                                                                                      '취소',
                                                                                      style: TextStyle(
                                                                                        color:
                                                                                            Colors.black,
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                  TextButton(
                                                                                    onPressed:
                                                                                        () => Navigator.pop(
                                                                                          context,
                                                                                          true,
                                                                                        ),
                                                                                    child: Text(
                                                                                      '삭제',
                                                                                      style: TextStyle(
                                                                                        color:
                                                                                            Colors.red,
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                        );
                                                                        if (confirm ==
                                                                            true) {
                                                                          await FirebaseFirestore
                                                                              .instance
                                                                              .collection(
                                                                                'posts',
                                                                              )
                                                                              .doc(
                                                                                postId,
                                                                              )
                                                                              .delete();
                                                                          ScaffoldMessenger.of(
                                                                            parentContext,
                                                                          ).showSnackBar(
                                                                            SnackBar(
                                                                              content: Text(
                                                                                '게시글이 삭제되었습니다.',
                                                                              ),
                                                                            ),
                                                                          );
                                                                        }
                                                                      },
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                      );
                                                    },
                                                  )
                                                  : IconButton(
                                                    icon: Icon(
                                                      Icons.more_horiz,
                                                    ),
                                                    onPressed: () {
                                                      showPostMenu(
                                                        parentContext,
                                                        postId,
                                                        myuser.userId,
                                                      );
                                                    },
                                                  ),
                                    ),
                                ],
                              ),

                              // Post Text
                              if (postData['text'].toString().isNotEmpty)
                                Text(
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
                              verticalSpace(5),
                              // Post Image
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
                              // Like/Comment Buttons
                              PostActions(postId: postId, postData: postData),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
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
