import 'package:ecommerece_app/features/home/widgets/guest_preview.dart/guest_comments.dart';
import 'package:go_router/go_router.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/core/widgets/safe_network_image.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:ecommerece_app/features/home/domain/feed_controller.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/features/home/widgets/guest_preview.dart/guest_post_actions.dart';
import 'package:ecommerece_app/features/home/widgets/post_item_components/natural_aspect_page_view.dart';
import 'package:ecommerece_app/features/home/widgets/post_item_components/post_menus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ecommerece_app/core/providers/firebase_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GuestPostItem extends ConsumerStatefulWidget {
  final Map<String, dynamic>? post;
  final String? postId;
  final double? imageWidth;
  final String? currentProfileUserId;

  const GuestPostItem({
    super.key,
    this.post,
    this.postId,
    this.imageWidth,
    this.currentProfileUserId,
  });

  @override
  ConsumerState<GuestPostItem> createState() => _GuestPostItemState();
}

class _GuestPostItemState extends ConsumerState<GuestPostItem> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _runWithLoading({
    required BuildContext context,
    required Future<void> Function() action,
    required String successMessage,
    required String errorMessage,
  }) async {
    final nav = Navigator.of(context);
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
      messenger.showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (e) {
      nav.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text('$errorMessage: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bool isGuest = ref.watch(currentUserIdProvider).isEmpty;
    final postsProvider = ref.read(feedControllerProvider.notifier);

    final String targetPostId =
        widget.postId ?? widget.post?['postId'] ?? 'unknown';
    final postData = widget.post ??
        ref.watch(feedControllerProvider.select((asyncList) {
          final list = asyncList.value;
          if (list == null) return null;
          for (var p in list) {
            if (p['postId'] == targetPostId) return p;
          }
          return null;
        }));

    if (postData == null) {
      return const SizedBox.shrink();
    }

    final userId = postData['userId'] as String? ?? '';
    final cachedUser =
        ref.watch(userCacheProvider.select((map) => map[userId]));

    if (cachedUser != null) {
      final displayName =
          cachedUser.name.isNotEmpty ? cachedUser.name : '삭제된 사용자';
      return _buildContent(
        context: context,
        myuser: cachedUser,
        postData: postData,
        isWaiting: false,
        isGuest: isGuest,
        displayName: displayName,
        profileUrl: cachedUser.url,
      );
    }

    if (userId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        postsProvider.loadUser(userId);
      });
    }

    return _buildContent(
      context: context,
      myuser: null,
      postData: postData,
      isWaiting: true,
      isGuest: isGuest,
      displayName: '로딩 중...',
      profileUrl: '',
    );
  }

  Widget _buildContent({
    required BuildContext context,
    required MyUser? myuser,
    required Map<String, dynamic> postData,
    required bool isWaiting,
    required bool isGuest,
    required String displayName,
    required String profileUrl,
  }) {
    final List imgUrls =
        (postData['imgUrls'] is List &&
                (postData['imgUrls'] as List).isNotEmpty)
            ? postData['imgUrls'] as List
            : const [];

    final bool isFromComments = postData['fromComments'] == true;

    if (isFromComments) {
      return _buildFromCommentsContent(
        context: context,
        myuser: myuser,
        postData: postData,
        isWaiting: isWaiting,
        isGuest: isGuest,
        displayName: displayName,
        profileUrl: profileUrl,
        imgUrls: imgUrls,
      );
    }

    return _buildFeedContent(
      context: context,
      myuser: myuser,
      postData: postData,
      isWaiting: isWaiting,
      isGuest: isGuest,
      displayName: displayName,
      profileUrl: profileUrl,
      imgUrls: imgUrls,
    );
  }

  // ── fromComments branch ───────────────────────────────────────────────
  Widget _buildFromCommentsContent({
    required BuildContext context,
    required MyUser? myuser,
    required Map<String, dynamic> postData,
    required bool isWaiting,
    required bool isGuest,
    required String displayName,
    required String profileUrl,
    required List imgUrls,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
          padding: EdgeInsets.only(top: 5.h, left: 10.w, right: 10.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAvatar(context, myuser),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDisplayName(displayName, isWaiting),
                        if (myuser != null && myuser.userId.isNotEmpty)
                          _buildFollowerCount(myuser),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (!isGuest)
                    _buildOtherPostMenu(
                      postData: postData,
                      myuser: myuser,
                      displayName: displayName,
                      profileUrl: profileUrl,
                    ),
                ],
              ),
              if (postData['text'] != null &&
                  postData['text'].toString().trim().isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 15.h),
                  child: Text(
                    postData['text'].toString(),
                    style: _postTextFullStyle,
                  ),
                ),
              SizedBox(height: 5.h),
              if (imgUrls.isNotEmpty)
                NaturalAspectPageView(
                  imgUrls: imgUrls,
                  pageController: _pageController,
                  explicitWidth: widget.imageWidth,
                  imageRatios: postData['imageRatios'] as Map?,
                ),
              SizedBox(height: 30.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  GuestPostActions(post: postData),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Container(height: 1.h, color: Colors.grey[600]),
                  ),
                  GestureDetector(
                    onTap: () => GoRouter.of(context).pop(),
                    child: const Icon(Icons.close),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

  // ── normal feed branch ────────────────────────────────────────────────
  Widget _buildFeedContent({
    required BuildContext context,
    required MyUser? myuser,
    required Map<String, dynamic> postData,
    required bool isWaiting,
    required bool isGuest,
    required String displayName,
    required String profileUrl,
    required List imgUrls,
  }) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (isWaiting) return;
          _openGuestComments(context, postData);
        },
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(context, myuser),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildDisplayName(displayName, isWaiting),
                    if (postData['text'] != null &&
                        postData['text'].toString().trim().isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 5.h),
                        child: _buildTextPreview(postData['text'].toString()),
                      ),
                    SizedBox(height: 5.h),
                    if (imgUrls.isNotEmpty)
                      NaturalAspectPageView(
                        imgUrls: imgUrls,
                        pageController: _pageController,
                        explicitWidth: screenWidth - 82.w,
                        imageRatios: postData['imageRatios'] as Map?,
                      ),
                    SizedBox(height: 5.h),
                    GuestPostActions(post: postData),
                  ],
                ),
              ),
              if (!isGuest)
                _buildOtherPostMenu(
                  postData: postData,
                  myuser: myuser,
                  displayName: displayName,
                  profileUrl: profileUrl,
                ),
            ],
          ),
        ),
      );
    }

  // ---------------------------------------------------------------------------
  // Shared sub-widgets
  // ---------------------------------------------------------------------------

  void _openGuestComments(
      BuildContext context, Map<String, dynamic> postData) {
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
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
          child: GuestComments(post: postData),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, MyUser? myuser) {
    return GestureDetector(
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
            image: safeNetworkImageProvider(myuser?.url ?? ''),
            fit: BoxFit.cover,
          ),
          shape: const OvalBorder(),
        ),
      ),
    );
  }

  Widget _buildDisplayName(String displayName, bool isWaiting) {
    if (isWaiting) {
      return Container(
        width: 80.w,
        height: 16.h,
        color: Colors.grey[300],
        margin: EdgeInsets.only(bottom: 2.h),
      );
    }
    return Text(
      displayName,
      style: TextStyles.abeezee16px400wPblack.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildFollowerCount(MyUser myuser) {
    final formatted = myuser.followerCount.toString().replaceAllMapped(
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

  Widget _buildOtherPostMenu({
    required Map<String, dynamic> postData,
    required MyUser? myuser,
    required String displayName,
    required String profileUrl,
  }) {
    return OtherPostMenu(
      postId: postData['postId'] ?? '',
      userId: myuser?.userId ?? '',
      onRunWithLoading: (context, action, success, error) => _runWithLoading(
        context: context,
        action: action,
        successMessage: success,
        errorMessage: error,
      ),
      displayName: displayName,
      profileUrl: profileUrl,
      postData: postData,
    );
  }
}

// =============================================================================
// Cached TextStyles
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
