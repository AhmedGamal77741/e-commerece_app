import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/core/providers/firebase_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:ecommerece_app/features/home/comments.dart';
import 'package:ecommerece_app/features/home/domain/feed_controller.dart';
import 'package:go_router/go_router.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/features/home/widgets/edit_post_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ecommerece_app/core/widgets/safe_network_image.dart';
import 'package:ecommerece_app/features/home/domain/follow_controller.dart';
import 'package:ecommerece_app/features/home/widgets/post_item_components/natural_aspect_page_view.dart';
import 'package:ecommerece_app/features/home/widgets/post_item_components/post_header_section.dart';
import 'package:ecommerece_app/features/home/widgets/post_item_components/post_action_buttons.dart';
import 'package:ecommerece_app/features/home/widgets/post_item_components/post_menus.dart';

final postDocumentStreamProvider =
    StreamProvider.family<DocumentSnapshot, String>((ref, postId) {
      return FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .snapshots();
    });

// =============================================================================
// PostItem — ConsumerStatefulWidget for stable PageController
// =============================================================================
class PostItem extends ConsumerStatefulWidget {
  final String postId;
  final bool fromComments;
  final bool showMoreButton;
  final double? imageWidth;
  final String? currentProfileUserId;
  final Map<String, dynamic>? postData;

  const PostItem({
    super.key,
    required this.postId,
    required this.fromComments,
    this.showMoreButton = true,
    this.imageWidth,
    this.currentProfileUserId,
    this.postData,
  });

  @override
  ConsumerState<PostItem> createState() => _PostItemState();
}

class _PostItemState extends ConsumerState<PostItem> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Action helpers
  // ---------------------------------------------------------------------------

  Future<void> _showEditDialog(
    BuildContext context,
    String currentText,
    List<String> currentImgUrls,
    String? currentCategoryId,
  ) async {
    final result = await showDialog<EditPostDialogResult>(
      context: context,
      builder: (ctx) => EditPostDialog(
        currentText: currentText,
        currentImgUrls: currentImgUrls,
        currentCategoryId: currentCategoryId,
      ),
    );

    if (result != null) {
      try {
        if (!context.mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            content: Row(
              children: [
                SizedBox(width: 16.w),
                const Text('게시글 수정 중...'),
              ],
            ),
          ),
        );

        await ref
            .read(feedControllerProvider.notifier)
            .updatePost(
              postId: widget.postId,
              text: result.text,
              networkImgUrls: result.imgUrls,
              newImages: result.newImages,
              categoryId: result.categoryId,
            );

        if (!context.mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('게시글이 수정되었습니다.')));
      } catch (e) {
        if (!context.mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('수정 실패: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _runWithLoading(
    BuildContext context,
    Future<void> Function() action,
    String successMsg,
    String errorPrefix,
  ) async {
    final nav = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);
    nav.push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        barrierColor: Colors.black26,
        pageBuilder: (_, __, ___) => AlertDialog(
          content: Row(
            children: [
              SizedBox(width: 16.w),
              const Text('처리 중...'),
            ],
          ),
        ),
      ),
    );
    try {
      await action();
      nav.pop();
      messenger.showSnackBar(SnackBar(content: Text(successMsg)));
    } catch (e) {
      nav.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text('$errorPrefix: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final postsProvider = ref.read(feedControllerProvider.notifier);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final double fromCommentsImageWidth = screenWidth - 20.w;

    // 1. Try to get post data from constructor or select it from feedControllerProvider
    final Map<String, dynamic>? postData =
        widget.postData ??
        ref.watch(
          feedControllerProvider.select((asyncList) {
            final list = asyncList.unwrapPrevious().value;
            if (list == null) return null;
            for (var p in list) {
              if (p['postId'] == widget.postId) return p;
            }
            return null;
          }),
        );

    // 2. If we have postData, render it immediately
    if (postData != null) {
      final userId = postData['userId'] as String? ?? '';
      final cachedUser = ref.watch(
        userCacheProvider.select((map) => map[userId]),
      );

      if (cachedUser == null && userId.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          postsProvider.loadUser(userId);
        });
      }

      return _buildPostItemContent(
        context: context,
        screenWidth: screenWidth,
        myuser: cachedUser,
        postData: postData,
        isWaiting: cachedUser == null,
        userMissing: false,
        fromCommentsImageWidth: fromCommentsImageWidth,
      );
    }

    // 3. Fallback: only if we have NO postData anywhere,
    // watch the realtime stream provider.
    final postStreamAsync = ref.watch(
      postDocumentStreamProvider(widget.postId),
    );

    return postStreamAsync.when(
      loading: () => _buildSkeleton(fromCommentsImageWidth),
      error: (err, stack) => const SizedBox.shrink(),
      data: (snapshot) {
        if (!snapshot.exists) return const SizedBox.shrink();
        final pData = snapshot.data() as Map<String, dynamic>?;
        if (pData == null || pData.isEmpty) return const SizedBox.shrink();
        pData['postId'] = widget.postId;

        final userId = pData['userId'] as String? ?? '';
        final cachedUser = ref.watch(
          userCacheProvider.select((map) => map[userId]),
        );

        if (cachedUser == null && userId.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            postsProvider.loadUser(userId);
          });
        }

        return _buildPostItemContent(
          context: context,
          screenWidth: screenWidth,
          myuser: cachedUser,
          postData: pData,
          isWaiting: cachedUser == null,
          userMissing: false,
          fromCommentsImageWidth: fromCommentsImageWidth,
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Skeleton placeholder
  // ---------------------------------------------------------------------------

  Widget _buildSkeleton(double width) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48.w,
            height: 48.h,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120.w,
                  height: 14.h,
                  color: Colors.grey[300],
                ),
                SizedBox(height: 8.h),
                Container(
                  width: double.infinity,
                  height: width * 0.6,
                  color: Colors.grey[300],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Main content
  // ---------------------------------------------------------------------------

  Widget _buildPostItemContent({
    required BuildContext context,
    required double screenWidth,
    required MyUser? myuser,
    required Map<String, dynamic> postData,
    required bool isWaiting,
    required bool userMissing,
    required double fromCommentsImageWidth,
  }) {
    final displayName = isWaiting
        ? '로딩 중...'
        : (myuser?.name.isNotEmpty == true ? myuser!.name : '삭제된 사용자');
    final String profileUrl =
        !userMissing && !isWaiting ? (myuser?.url ?? '') : '';
    final currentUid = ref.watch(currentUserIdProvider);
    final bool isMyPost =
        !userMissing && !isWaiting && myuser!.userId == currentUid;

    final String userId = myuser?.userId ?? '';
    final String? syncName = ref.watch(contactNicknameProvider(userId));

    final List imgUrls =
        (postData['imgUrls'] is List && (postData['imgUrls'] as List).isNotEmpty)
            ? postData['imgUrls'] as List
            : const [];

    if (widget.fromComments) {
      return _buildFromCommentsLayout(
        context: context,
        postData: postData,
        myuser: myuser,
        displayName: displayName,
        profileUrl: profileUrl,
        isWaiting: isWaiting,
        userMissing: userMissing,
        isMyPost: isMyPost,
        imgUrls: imgUrls,
        fromCommentsImageWidth: fromCommentsImageWidth,
      );
    }

    return _buildFeedLayout(
      context: context,
      screenWidth: screenWidth,
      postData: postData,
      myuser: myuser,
      displayName: displayName,
      profileUrl: profileUrl,
      isWaiting: isWaiting,
      isMyPost: isMyPost,
      userId: userId,
      syncName: syncName,
      imgUrls: imgUrls,
    );
  }

  // ---------------------------------------------------------------------------
  // FromComments layout (detail view)
  // ---------------------------------------------------------------------------

  Widget _buildFromCommentsLayout({
    required BuildContext context,
    required Map<String, dynamic> postData,
    required MyUser? myuser,
    required String displayName,
    required String profileUrl,
    required bool isWaiting,
    required bool userMissing,
    required bool isMyPost,
    required List imgUrls,
    required double fromCommentsImageWidth,
  }) {
    return Padding(
      padding: EdgeInsets.only(top: 5.h, left: 10.w, right: 10.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PostHeaderSection(
              myuser: myuser,
              displayName: displayName,
              profileUrl: profileUrl,
              isWaiting: isWaiting,
              userMissing: userMissing,
              isMyPost: isMyPost,
              currentProfileUserId: widget.currentProfileUserId,
              postId: widget.postId,
              postData: postData,
            ),
            if (postData['text'] != null &&
                postData['text'].toString().trim().isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 15.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        postData['text'].toString(),
                        style: _postTextFullStyle,
                      ),
                    ),
                    if (widget.showMoreButton)
                      _buildPostMenu(
                        context: context,
                        postData: postData,
                        myuser: myuser,
                        displayName: displayName,
                        profileUrl: profileUrl,
                        isMyPost: isMyPost,
                        imgUrls: imgUrls,
                      ),
                  ],
                ),
              ),
            SizedBox(height: 5.h),
            if (imgUrls.isNotEmpty)
              NaturalAspectPageView(
                imgUrls: imgUrls,
                pageController: _pageController,
                explicitWidth: fromCommentsImageWidth,
                imageRatios: postData['imageRatios'] as Map?,
              ),
            SizedBox(height: 30.h),
            PostActionButtons(postId: widget.postId, postData: postData),
          ],
        ),
      );
    }

  // ---------------------------------------------------------------------------
  // Feed layout (list item)
  // ---------------------------------------------------------------------------

  Widget _buildFeedLayout({
    required BuildContext context,
    required double screenWidth,
    required Map<String, dynamic> postData,
    required MyUser? myuser,
    required String displayName,
    required String profileUrl,
    required bool isWaiting,
    required bool isMyPost,
    required String userId,
    required String? syncName,
    required List imgUrls,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          GestureDetector(
            onTap: () {
              if (isWaiting) return;
              if (myuser != null &&
                  widget.currentProfileUserId != myuser.userId) {
                context.pushNamed(
                  Routes.profileTabScreen,
                  extra: {'userId': myuser.userId},
                );
              }
            },
            child: Container(
              width: 48.w,
              height: 48.h,
              decoration: ShapeDecoration(
                image: DecorationImage(
                  image: safeNetworkImageProvider(profileUrl),
                  fit: BoxFit.cover,
                ),
                shape: const OvalBorder(),
              ),
            ),
          ),
          SizedBox(width: 10.w),

          // Content
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (isWaiting) return;
                _openComments(context);
              },
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name row
                    _buildNameRow(
                      displayName: displayName,
                      isWaiting: isWaiting,
                      syncName: syncName,
                      userId: userId,
                    ),

                    // Text preview
                    if (postData['text'] != null &&
                        postData['text'].toString().trim().isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 5.h),
                        child: _buildTextPreview(postData['text'].toString()),
                      ),
                    SizedBox(height: 5.h),

                    // Images
                    if (imgUrls.isNotEmpty)
                      NaturalAspectPageView(
                        imgUrls: imgUrls,
                        pageController: _pageController,
                        explicitWidth: screenWidth - 82.w,
                        imageRatios: postData['imageRatios'] as Map?,
                      ),
                  ],
                ),
              ),
            ),

            // Post menu
            if (widget.showMoreButton)
              _buildPostMenu(
                context: context,
                postData: postData,
                myuser: myuser,
                displayName: displayName,
                profileUrl: profileUrl,
                isMyPost: isMyPost,
                imgUrls: imgUrls,
              ),
          ],
        ),
      );
    }

  // ---------------------------------------------------------------------------
  // Shared sub-widgets
  // ---------------------------------------------------------------------------

  void _openComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.sizeOf(context).height * 0.95,
        decoration: const BoxDecoration(
          color: Color(0xFFF2F2F2),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Comments(postId: widget.postId),
        ),
      ),
    );
  }

  Widget _buildNameRow({
    required String displayName,
    required bool isWaiting,
    required String? syncName,
    required String userId,
  }) {
    return Row(
      children: [
        if (isWaiting)
          Container(
            width: 80.w,
            height: 16.h,
            color: Colors.grey[300],
            margin: EdgeInsets.only(bottom: 2.h),
          )
        else
          Flexible(
            child: Text(
              displayName,
              style: TextStyles.abeezee16px400wPblack.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        if (!isWaiting &&
            syncName != null &&
            syncName.isNotEmpty) ...[
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              '@$syncName',
              style: _nicknameStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextPreview(String text) {
    if (text.length > 110) {
      return RichText(
        text: TextSpan(
          text: '${text.substring(0, 110)}...\n',
          style: _postTextPreviewStyle,
          children: [
            TextSpan(
              text: '(더보기)',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    return Text(text, style: _postTextPreviewStyle);
  }

  Widget _buildPostMenu({
    required BuildContext context,
    required Map<String, dynamic> postData,
    required MyUser? myuser,
    required String displayName,
    required String profileUrl,
    required bool isMyPost,
    required List imgUrls,
  }) {
    if (myuser == null) {
      return const SizedBox.shrink();
    }
    if (isMyPost) {
      return OwnPostMenu(
        postId: widget.postId,
        currentText: postData['text'] ?? '',
        onEdit: () => _showEditDialog(
          context,
          postData['text'] ?? '',
          imgUrls.cast<String>(),
          postData['categoryId'] as String?,
        ),
      );
    }
    return OtherPostMenu(
      postId: widget.postId,
      userId: myuser.userId,
      onRunWithLoading: _runWithLoading,
      displayName: displayName,
      profileUrl: profileUrl,
      postData: postData,
    );
  }
}

// =============================================================================
// Cached TextStyles — avoids re-creating on every build
// =============================================================================

final _postTextFullStyle = TextStyle(
  color: const Color(0xFF343434),
  fontSize: 18.sp,
  fontFamily: 'NotoSans',
  fontWeight: FontWeight.w500,
  height: 1.40.h,
  letterSpacing: -0.09.w,
);

final _postTextPreviewStyle = TextStyle(
  color: const Color(0xFF343434),
  fontSize: 16.sp,
  fontFamily: 'NotoSans',
  fontWeight: FontWeight.w400,
  height: 1.40.h,
  letterSpacing: -0.09.w,
);

final _nicknameStyle = TextStyle(
  fontSize: 14.sp,
  color: Colors.grey[600],
  fontWeight: FontWeight.w400,
);
