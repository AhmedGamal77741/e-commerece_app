import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/features/cart/domain/cart_controller.dart';
import 'package:ecommerece_app/features/chat/widgets/chat_post_share.dart';

import 'package:ecommerece_app/features/home/comments.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerece_app/features/home/domain/feed_controller.dart';
import 'package:ecommerece_app/features/home/models/comment_model.dart';
import 'package:go_router/go_router.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/features/home/domain/follow_controller.dart';
import 'package:ecommerece_app/core/providers/firebase_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ecommerece_app/core/widgets/safe_network_image.dart';
import 'package:ecommerece_app/core/widgets/user_name_header.dart';
import 'package:ecommerece_app/core/widgets/full_screen_image_viewer.dart';

class CommentItem extends ConsumerStatefulWidget {
  final Comment comment;
  final String postId;
  const CommentItem({super.key, required this.comment, required this.postId});

  @override
  ConsumerState<CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends ConsumerState<CommentItem> {
  String get currentUserId => ref.watch(currentUserIdProvider);
  final GlobalKey _commentKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    List<String> likedBy = List<String>.from(widget.comment.likedBy);
    bool isLiked = likedBy.contains(currentUserId);

    return Padding(
      key: _commentKey,
      padding: EdgeInsets.only(left: 10.w),
      child: InkWell(
        onLongPress: () {
          debugPrint('Long press detected!'); // Debug
          _showCommentMenu(widget.comment.userId);
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                context.pushNamed(
                  Routes.profileTabScreen,
                  extra: {'userId': widget.comment.userId},
                );
              },
              child: Container(
                width: 40.w,
                height: 40.h,
                decoration: ShapeDecoration(
                  image: DecorationImage(
                    image: safeNetworkImageProvider(
                      widget.comment.userImage.toString(),
                      maxCacheWidth: 120,
                    ),
                    fit: BoxFit.cover,
                  ),
                  shape: OvalBorder(),
                ),
              ),
            ),
            horizontalSpace(4),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: 10.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    verticalSpace(3),
                    UserNameHeader(
                      userId: widget.comment.userId,
                      accountName: widget.comment.userName ?? '',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w400,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      spacing: 4.w,
                      children: [
                        Flexible(
                          fit: FlexFit.loose,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.comment.text.isNotEmpty) ...[
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6.r),
                                    color: Colors.white,
                                    border: Border.all(color: const Color(0xFFE0E0E0), width: 1.0),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 5.w,
                                      vertical: 2.h,
                                    ),
                                    child: Text(
                                      widget.comment.text,
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
                              ],
                              if (widget.comment.postData != null) ...[
                                if (widget.comment.text.isNotEmpty)
                                  SizedBox(height: 6.h),
                                ChatPostShareWidget(
                                  type: 'post',
                                  imageUrl: getPostImageUrl(widget.comment.postData),
                                  authorName:
                                      (widget.comment.postData!['authorName'] as String?)?.isNotEmpty == true
                                          ? widget.comment.postData!['authorName'] as String
                                          : (widget.comment.postData!['userId'] as String? ?? ''),
                                  postTitle: widget.comment.postData!['text'] as String? ?? '',
                                  onTap: () {
                                    final postId = widget.comment.postData!['postId'] as String? ?? widget.comment.postData!['id'] as String? ?? '';
                                    if (postId.isEmpty) return;
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder:
                                          (context) => Container(
                                            height:
                                                MediaQuery.of(
                                                  context,
                                                ).size.height *
                                                0.95,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFF2F2F2),
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                    top: Radius.circular(20),
                                                  ),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                    top: Radius.circular(20),
                                                  ),
                                              child: Comments(
                                                postId: postId,
                                              ),
                                            ),
                                          ),
                                    );
                                  },
                                ),
                              ],
                              if (widget.comment.productData != null) ...[
                                if (widget.comment.text.isNotEmpty)
                                  SizedBox(height: 6.h),
                                ChatPostShareWidget(
                                  type: 'product',
                                  imageUrl: widget.comment.productData!.imgUrl!,
                                  postTitle:
                                      '${widget.comment.productData!.pricePoints[0].price.toString()} 원',
                                  authorName:
                                      widget.comment.productData!.productName,
                                  onTap: () async {
                                    bool isSub = await isUserSubscribed();
                                    if (!context.mounted) return;
                                    context.pushNamed(
                                      'productDetails',
                                      pathParameters: {
                                        'productId': widget.comment.productData!.productId,
                                      },
                                      extra: {
                                        'product': widget.comment.productData!,
                                        'isSub': isSub,
                                        'arrivalDay':
                                            widget
                                                .comment
                                                .productData!
                                                .arrivalDate ?? '',
                                      },
                                    );
                                  },
                                ),
                              ],
                              if (widget.comment.imageUrl != null &&
                                  widget.comment.imageUrl!.isNotEmpty) ...[
                                if (widget.comment.text.isNotEmpty)
                                  SizedBox(height: 6.h),
                                GestureDetector(
                                  onTap: () {
                                    FullScreenImageViewer.openSingle(
                                      context,
                                      widget.comment.imageUrl!,
                                    );
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: SafeNetworkImage(
                                      url: widget.comment.imageUrl!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 4.w,
                          children: [
                            InkWell(
                              onTap: () {
                                ref
                                    .read(feedControllerProvider.notifier)
                                    .toggleCommentLike(
                                      widget.postId,
                                      widget.comment.id,
                                    );
                                setState(() {
                                  isLiked = !isLiked;
                                });
                              },
                              child: ImageIcon(
                                AssetImage(
                                  isLiked
                                      ? "assets/icon=like,status=off (1).png"
                                      : "assets/icon=like,status=off.png",
                                ),
                                color:
                                    isLiked ? Color(0xFF280404) : Colors.black,
                              ),
                            ),
                            Text(
                              widget.comment.likes.toString(),
                              style: TextStyle(
                                color: const Color(0xFF343434),
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
            ),
          ],
        ),
      ),
    );
  }

  void _showCommentMenu(String commentUserId) {
    debugPrint('Showing menu for user: $commentUserId'); // Debug

    final currentUserId = ref.watch(currentUserIdProvider);

    // Don't show menu if it's the current user's own comment
    if (commentUserId == currentUserId) {
      debugPrint('Cannot show menu for own comment');
      return;
    }

    final RenderBox? renderBox =
        _commentKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      debugPrint('RenderBox is null');
      return;
    }

    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        renderBox.localToGlobal(
          renderBox.size.centerLeft(Offset.zero),
          ancestor: overlay,
        ),
        renderBox.localToGlobal(
          renderBox.size.centerRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      elevation: 8,
      items: [
        // Follow/Unfollow/Request Option
        PopupMenuItem<String>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: Consumer(
            builder: (context, ref, _) {
              final userAsync = ref.watch(userProfileDocProvider(commentUserId));
              return userAsync.when(
                data: (doc) {
                  if (doc == null) {
                    return SizedBox(height: 50.h, child: const SizedBox.shrink());
                  }
                  final commentUserData = doc.data() as Map<String, dynamic>?;
                  if (commentUserData == null) {
                    return const SizedBox.shrink();
                  }

                  final isPrivate = commentUserData['isPrivate'] ?? false;
                  final currentUserId = ref.read(currentUserIdProvider);

                  final isFollowing = ref.watch(isFollowingProvider(commentUserId)).value ?? false;
                  final hasRequest = ref.watch(hasFollowRequestProvider(commentUserId)).value ?? false;

                  String buttonText = '구독';

                  if (isFollowing) {
                    buttonText = '구독 취소';
                  } else if (isPrivate && hasRequest) {
                    buttonText = '요청 취소';
                  } else if (isPrivate) {
                    buttonText = '구독 요청';
                  }

                  return InkWell(
                    onTap: () async {
                      Navigator.pop(context);
                      if (isFollowing) {
                        await ref
                            .read(followControllerProvider)
                            .toggleFollow(commentUserId);
                      } else if (isPrivate && !hasRequest) {
                        await ref
                            .read(followControllerProvider)
                            .sendFollowRequest(
                              commentUserId,
                              currentUserId,
                            );
                      } else if (isPrivate && hasRequest) {
                        await ref
                            .read(followControllerProvider)
                            .cancelFollowRequest(
                              commentUserId,
                              currentUserId,
                            );
                      } else {
                        await ref
                            .read(followControllerProvider)
                            .toggleFollow(commentUserId);
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('작업이 완료되었습니다')),
                        );
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      child: Text(
                        buttonText,
                        style: TextStyle(
                          color: const Color(0xFF343434),
                          fontSize: 13.sp,
                          fontFamily: 'NotoSans',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                },
                loading: () => SizedBox(height: 50.h, child: const SizedBox.shrink()),
                error: (e, st) => const SizedBox.shrink(),
              );
            },
          ),
        ),
        // Divider

        // Block Option
        PopupMenuItem<String>(
          value: 'block',

          child: Text(
            '차단',
            style: TextStyle(
              color: Colors.black,
              fontSize: 13.sp,
              fontFamily: 'NotoSans',
              fontWeight: FontWeight.w400,
            ),
          ),
        ),

        // Report and Block Option
        PopupMenuItem<String>(
          value: 'report',

          child: Text(
            '신고 및 차단',
            style: TextStyle(
              color: Colors.black,
              fontSize: 13.sp,
              fontFamily: 'NotoSans',
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    ).then((value) async {
      if (!mounted) return;
      if (value == 'block') {
        await ref
            .read(feedControllerProvider.notifier)
            .blockUser(userIdToBlock: commentUserId);
      } else if (value == 'report') {
        await ref
            .read(feedControllerProvider.notifier)
            .reportComment(
              reportedUserId: commentUserId,
              postId: widget.postId,
              commentId: widget.comment.id,
            );
        await ref
            .read(feedControllerProvider.notifier)
            .blockUser(userIdToBlock: commentUserId);
      }
    });
  }
}
