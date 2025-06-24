import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/core/helpers/extensions.dart';
import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:ecommerece_app/features/auth/signup/data/signup_functions.dart';
import 'package:ecommerece_app/features/home/data/post_provider.dart';
import 'package:ecommerece_app/features/home/models/comment_model.dart';
import 'package:ecommerece_app/features/home/widgets/comment_item.dart';
import 'package:ecommerece_app/features/home/widgets/post_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class Comments extends StatefulWidget {
  const Comments({super.key, required this.postId});
  final String postId;

  @override
  State<Comments> createState() => _CommentsState();
}

class _CommentsState extends State<Comments> {
  bool liked = false;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  MyUser? currentUser = MyUser(userId: "", email: "", name: "", url: "");
  bool _isLoading = true;
  String? postAuthorId;
  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void initState() {
    super.initState();
    Provider.of<PostsProvider>(context, listen: false).startListening();
    _loadData();
    _getPostAuthorId();
  }

  Future<void> _getPostAuthorId() async {
    // Get the post's authorId from Firestore
    final doc =
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .get();
    if (doc.exists) {
      setState(() {
        postAuthorId = (doc.data() as Map<String, dynamic>)['userId'];
      });
    }
  }

  // Async function that uses await
  Future<void> _loadData() async {
    try {
      currentUser = await FirebaseUserRepo().user.first;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print(e);
      throw e;
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await Provider.of<PostsProvider>(
        context,
        listen: false,
      ).addComment(widget.postId, text);

      _commentController.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('댓글 추가에 실패했습니다: $e')));
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final postsProvider = Provider.of<PostsProvider>(context, listen: false);
    // Load comments if not already loaded
    if (postsProvider.getComments(widget.postId).isEmpty &&
        !postsProvider.isLoadingComments(widget.postId)) {
      // Start listening to comments for this post
      postsProvider.listenToComments(widget.postId);
    }
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  Padding(
                    padding: EdgeInsets.only(right: 10.w),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: PostItem(
                            postId: widget.postId,
                            fromComments: true,
                            showMoreButton:
                                false, // Hide the More button in comments context
                          ),
                        ),
                        if (postAuthorId != null &&
                            postAuthorId != currentUser?.userId)
                          StreamBuilder<DocumentSnapshot>(
                            stream:
                                FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(currentUser?.userId)
                                    .collection('following')
                                    .doc(postAuthorId)
                                    .snapshots(),
                            builder: (context, snapshot) {
                              final isFollowing =
                                  snapshot.hasData && snapshot.data!.exists;
                              return Padding(
                                padding: EdgeInsets.only(top: 8.h, right: 8.w),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        isFollowing
                                            ? Colors.grey[300]
                                            : ColorsManager.primary600,
                                    foregroundColor:
                                        isFollowing
                                            ? Colors.black
                                            : Colors.white,
                                    minimumSize: Size(80.w, 36.h),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12.w,
                                      vertical: 0,
                                    ),
                                    textStyle: TextStyle(
                                      fontSize: 14.sp,
                                      fontFamily: 'NotoSans',
                                      fontWeight: FontWeight.w500,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  onPressed: () async {
                                    final followingRef = FirebaseFirestore
                                        .instance
                                        .collection('users')
                                        .doc(currentUser?.userId)
                                        .collection('following')
                                        .doc(postAuthorId);
                                    final followerRef = FirebaseFirestore
                                        .instance
                                        .collection('users')
                                        .doc(postAuthorId)
                                        .collection('followers')
                                        .doc(currentUser?.userId);
                                    if (isFollowing) {
                                      await followingRef.delete();
                                      await followerRef.delete();
                                    } else {
                                      await followingRef.set({
                                        'createdAt':
                                            FieldValue.serverTimestamp(),
                                      });
                                      await followerRef.set({
                                        'createdAt':
                                            FieldValue.serverTimestamp(),
                                      });
                                    }
                                  },
                                  child: Text(isFollowing ? '구독 취소' : '구독'),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                  Divider(height: 50.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 10,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 20.0.w),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 10,
                          children: [
                            Text(
                              '댓글',
                              style: TextStyle(
                                color: const Color(0xFF121212),
                                fontSize: 16,
                                fontFamily: 'NotoSans',
                                fontWeight: FontWeight.w400,
                                height: 1.40,
                              ),
                            ),
                            Text(
                              postsProvider
                                  .getComments(widget.postId)
                                  .length
                                  .toString(),
                              style: TextStyle(
                                color: const Color(0xFF5F5F5F),
                                fontSize: 16,
                                fontFamily: 'NotoSans',
                                fontWeight: FontWeight.w400,
                                height: 1.40,
                                letterSpacing: -0.09,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(right: 20.0.w),
                        child: InkWell(
                          onTap: () {
                            context.pop();
                          },
                          child: Icon(Icons.close),
                        ),
                      ),
                    ],
                  ),
                  verticalSpace(30),
                  Selector<PostsProvider, List<Comment>>(
                    selector:
                        (_, provider) => provider.getComments(widget.postId),
                    builder: (context, comments, child) {
                      if (postsProvider.isLoadingComments(widget.postId) &&
                          comments.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.h),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (comments.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.h),
                            child: Text(
                              '아직 댓글이 없습니다. 첫 번째 댓글을 남겨보세요!',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14.sp,
                                fontFamily: 'NotoSans',
                              ),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final comment = comments[index];
                          return CommentItem(
                            comment: comment,
                            postId: widget.postId,
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

            Container(
              height: 60.h,
              padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 15.w),
              child: Row(
                children: [
                  // Comment icon
                  Container(
                    width: 30.w,
                    height: 30.h,
                    decoration: ShapeDecoration(
                      image: DecorationImage(
                        image: NetworkImage(currentUser!.url.toString()),
                        fit: BoxFit.cover,
                      ),
                      shape: OvalBorder(),
                    ),
                  ),
                  SizedBox(width: 10.w),

                  // Comment input field
                  Expanded(
                    flex: 4,
                    child: TextFormField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 10.h,
                        ),
                        labelText: "댓글 추가",
                        labelStyle: TextStyles.abeezee16px400wP600,
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: ColorsManager.primary600,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: ColorsManager.primary600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    icon: Icon(Icons.send),
                    color: ColorsManager.primary600,
                    iconSize: 25.sp,
                    onPressed: _isSubmitting ? null : _submitComment,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
