import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/core/providers/firebase_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:ecommerece_app/features/chat/services/contacts_service.dart';
import 'package:ecommerece_app/features/home/comments.dart';
import 'package:ecommerece_app/features/home/domain/feed_controller.dart';
import 'package:go_router/go_router.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/features/home/widgets/edit_post_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
// PostItem — converted to StatefulWidget so PageController is stable
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

class _PostItemState extends ConsumerState<PostItem> {
  // Stable PageController that survives rebuilds
  final PageController _pageController = PageController();

  // Cache contact nickname to avoid re-firing on every rebuild
  String? _cachedUserId;
  Future<String?>? _nicknameFuture;

  Future<String?> _getNickname(String userId) {
    if (userId == _cachedUserId && _nicknameFuture != null) {
      return _nicknameFuture!;
    }
    _cachedUserId = userId;
    _nicknameFuture = ContactService().getContactNickname(userId);
    return _nicknameFuture!;
  }


  @override
  void initState() {
    super.initState();
    // Comment listening is demand-driven — called when user opens comments
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _showEditDialog(
    BuildContext context,
    String currentText,
    List<String> currentImgUrls,
    String? currentCategoryId,
  ) async {
    final result = await showDialog<EditPostDialogResult>(
      context: context,
      builder:
          (ctx) => EditPostDialog(
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
          builder:
              (ctx) => AlertDialog(
                content: Row(
                  children: [
                    const SizedBox.shrink(),
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
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('게시글이 수정되었습니다.')));
      } catch (e) {
        if (!context.mounted) return;
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
        pageBuilder:
            (_, __, ___) => AlertDialog(
              content: Row(
                children: [
                  const SizedBox.shrink(),
                  SizedBox(width: 16.w),
                  const Text('신고 처리 중...'),
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

  @override
  Widget build(BuildContext context) {
    final postsProvider = ref.read(feedControllerProvider.notifier);
    final double fromCommentsImageWidth = MediaQuery.of(context).size.width - 20.w;

    // 1. Try to get post data from constructor or select it from feedControllerProvider
    final Map<String, dynamic>? postData =
        widget.postData ??
        ref.watch(
          feedControllerProvider.select((asyncList) {
            final list = asyncList.value;
            if (list == null) return null;
            for (var p in list) {
              if (p['postId'] == widget.postId) return p;
            }
            return null;
          }),
        );

    // 3. If we have postData, render it immediately! No stream connection, no skeleton shimmer!
    if (postData != null) {
      final cachedUser = ref.watch(userCacheProvider.select((map) => map[postData['userId']]));

      if (cachedUser == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          postsProvider.loadUser(postData['userId']);
        });
      }

      return _buildPostItemContent(
        context: context,
        myuser: cachedUser,
        postData: postData,
        isWaiting: cachedUser == null,
        userMissing: false,
        fromCommentsImageWidth: fromCommentsImageWidth,
      );
    }

    // 4. Fallback: only if we have NO postData anywhere (e.g. deep link or search screen first load),
    // then and only then watch the realtime stream provider.
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

        final cachedUser = ref.watch(userCacheProvider.select((map) => map[pData['userId']]));

        if (cachedUser == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            postsProvider.loadUser(pData['userId']);
          });
        }

        return _buildPostItemContent(
          context: context,
          myuser: cachedUser,
          postData: pData,
          isWaiting: cachedUser == null,
          userMissing: false,
          fromCommentsImageWidth: fromCommentsImageWidth,
        );
      },
    );
  }

  /// Cheap skeleton shown while the post/user data is first loading.
  /// Avoids building the full widget tree just to wrap it in a shimmer.
  Widget _buildSkeleton(double width) {
    return _PulsingSkeleton(
      child: Padding(
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
      ),
    );
  }

  Widget _buildPostItemContent({
    required BuildContext context,
    required MyUser? myuser,
    required Map<String, dynamic> postData,
    required bool isWaiting,
    required bool userMissing,
    required double fromCommentsImageWidth,
  }) {
    final displayName =
        isWaiting
            ? '로딩 중...'
            : (myuser?.name.isNotEmpty == true ? myuser!.name : '삭제된 사용자');
    final String profileUrl =
        !userMissing && !isWaiting ? (myuser?.url ?? '') : '';
    final currentUid = ref.watch(currentUserIdProvider);
    final bool isMyPost =
        !userMissing && !isWaiting && myuser!.userId == currentUid;

    final String userId = myuser == null ? '' : myuser.userId;
    final contactService = ContactService();
    final bool nameMapLoaded = contactService.isNameMapLoaded();
    final String? syncName = nameMapLoaded ? contactService.getContactNicknameSync(userId) : null;

    final List imgUrls =
        (postData['imgUrls'] != null &&
                (postData['imgUrls'] as List).isNotEmpty)
            ? postData['imgUrls'] as List
            : [];

    return IgnorePointer(
      ignoring: isWaiting,
      child: Column(
        children: [
          if (widget.fromComments)
            Padding(
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
                              style: TextStyle(
                                color: const Color(0xFF343434),
                                fontSize: 18.sp,
                                fontFamily: 'NotoSans',
                                fontWeight: FontWeight.w500,
                                height: 1.40.h,
                                letterSpacing: -0.09.w,
                              ),
                            ),
                          ),
                          if (widget.showMoreButton)
                            isMyPost
                                ? OwnPostMenu(
                                  postId: widget.postId,
                                  currentText: postData['text'] ?? '',
                                  onEdit:
                                      () => _showEditDialog(
                                        context,
                                        postData['text'] ?? '',
                                        imgUrls.cast<String>(),
                                        postData['categoryId'] as String?,
                                      ),
                                )
                                : OtherPostMenu(
                                  postId: widget.postId,
                                  userId: myuser?.userId ?? '',
                                  onRunWithLoading: _runWithLoading,
                                  displayName: displayName,
                                  profileUrl: profileUrl,
                                  postData: postData,
                                ),
                        ],
                      ),
                    ),
                  verticalSpace(5),
                  if (imgUrls.isNotEmpty)
                    NaturalAspectPageView(
                      imgUrls: imgUrls,
                      pageController: _pageController,
                      explicitWidth: fromCommentsImageWidth,
                    ),
                  verticalSpace(30),
                  PostActionButtons(postId: widget.postId, postData: postData),
                ],
              ),
            ),

          // Feed path: wrap in a plain Padding — Screenshot only needed on share action
          if (!widget.fromComments)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () {
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
                          image: const AssetImage('assets/avatar.png') as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                        shape: const OvalBorder(),
                      ),
                    ),
                  ),
                  horizontalSpace(10),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder:
                              (context) => Container(
                                height:
                                    MediaQuery.of(context).size.height * 0.95,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF2F2F2),
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                  child: Comments(postId: widget.postId),
                                ),
                              ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              isWaiting
                                  ? _PulsingSkeleton(
                                    child: Container(
                                      width: 80.w,
                                      height: 16.h,
                                      color: Colors.grey[300],
                                      margin: EdgeInsets.only(bottom: 2.h),
                                    ),
                                  )
                                  : Flexible(
                                    child: Text(
                                      displayName,
                                      style: TextStyles.abeezee16px400wPblack
                                          .copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              horizontalSpace(4),
                              if (nameMapLoaded) ...[
                                if (syncName != null && syncName.isNotEmpty) ...[
                                  horizontalSpace(4),
                                  Flexible(
                                    child: Text(
                                      '@$syncName',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w400,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ] else ...[
                                FutureBuilder<String?>(
                                  future: _getNickname(userId),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const SizedBox.shrink();
                                    }
                                    if (snapshot.hasError ||
                                        !snapshot.hasData ||
                                        snapshot.data == null) {
                                      return const SizedBox.shrink();
                                    }
                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        horizontalSpace(4),
                                        Flexible(
                                          child: Text(
                                            '@${snapshot.data!}',
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w400,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                          if (postData['text'] != null &&
                              postData['text'].toString().trim().isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(top: 5.h),
                              child: Builder(
                                builder: (context) {
                                  final String text =
                                      postData['text'].toString();
                                  if (text.length > 110) {
                                    return RichText(
                                      text: TextSpan(
                                        text: '${text.substring(0, 110)}...\n',
                                        style: TextStyle(
                                          color: const Color(0xFF343434),
                                          fontSize: 16.sp,
                                          fontFamily: 'NotoSans',
                                          fontWeight: FontWeight.w400,
                                          height: 1.40.h,
                                          letterSpacing: -0.09.w,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: '(더보기)',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                  return Text(
                                    text,
                                    style: TextStyle(
                                      color: const Color(0xFF343434),
                                      fontSize: 16.sp,
                                      fontFamily: 'NotoSans',
                                      fontWeight: FontWeight.w400,
                                      height: 1.40.h,
                                      letterSpacing: -0.09.w,
                                    ),
                                  );
                                },
                              ),
                            ),
                          verticalSpace(5),
                          if (imgUrls.isNotEmpty)
                            NaturalAspectPageView(
                              imgUrls: imgUrls,
                              pageController: _pageController,
                              explicitWidth:
                                  MediaQuery.of(context).size.width - 82.w,
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (widget.showMoreButton)
                    isMyPost
                        ? OwnPostMenu(
                          postId: widget.postId,
                          currentText: postData['text'] ?? '',
                          onEdit:
                              () => _showEditDialog(
                                context,
                                postData['text'] ?? '',
                                imgUrls.cast<String>(),
                                postData['categoryId'] as String?,
                              ),
                        )
                        : OtherPostMenu(
                          postId: widget.postId,
                          userId: myuser?.userId ?? '',
                          onRunWithLoading: _runWithLoading,
                          displayName: displayName,
                          profileUrl: profileUrl,
                          postData: postData,
                        ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PulsingSkeleton extends StatelessWidget {
  final Widget child;
  const _PulsingSkeleton({required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
