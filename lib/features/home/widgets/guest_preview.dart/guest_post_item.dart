import 'package:ecommerece_app/features/home/widgets/guest_preview.dart/guest_comments.dart';
import 'package:go_router/go_router.dart';
import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
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
import 'package:cached_network_image/cached_network_image.dart';

class GuestPostItem extends ConsumerStatefulWidget {
  final Map<String, dynamic> post;

  /// Caller-supplied explicit image width.
  /// GuestComments computes this via MediaQuery and passes it in so
  /// NaturalAspectPageView always has the correct pixel width even when
  /// it lives inside a Column/SingleChildScrollView (unbounded width).
  final double? imageWidth;
  final String? currentProfileUserId;

  const GuestPostItem({
    super.key,
    required this.post,
    this.imageWidth,
    this.currentProfileUserId,
  });

  @override
  ConsumerState<GuestPostItem> createState() => _GuestPostItemState();
}

class _GuestPostItemState extends ConsumerState<GuestPostItem> {
  final PageController _pageController = PageController();

  String? _cachedProfileUserId;
  Future<MyUser>? _userFuture;

  Future<MyUser> _getProfileUser(String userId, dynamic postsProvider) {
    if (userId == _cachedProfileUserId && _userFuture != null) {
      return _userFuture!;
    }
    _cachedProfileUserId = userId;
    _userFuture = postsProvider.loadUser(userId);
    return _userFuture!;
  }

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
        pageBuilder:
            (_, __, ___) => AlertDialog(
              content: Row(
                children: [
                  const SizedBox.shrink(),
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
    final bool isGuest = ref.watch(currentUserIdProvider).isEmpty;
    final postsProvider = ref.read(feedControllerProvider.notifier);
    final cachedUser = postsProvider.getUser(widget.post['userId']);

    if (cachedUser != null) {
      final displayName = cachedUser.name.isNotEmpty == true ? cachedUser.name : '삭제된 사용자';
      final profileUrl = cachedUser.url;
      return _buildPostItemContent(
        context: context,
        myuser: cachedUser,
        isWaiting: false,
        userMissing: false,
        isGuest: isGuest,
        displayName: displayName,
        profileUrl: profileUrl,
      );
    }

    return FutureBuilder<MyUser>(
      future: _getProfileUser(widget.post['userId'], postsProvider),
      builder: (context, snapshot) {
        final isWaiting =
            snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData;
        final bool userMissing =
            !isWaiting &&
            (snapshot.hasError ||
                !snapshot.hasData ||
                (snapshot.data?.userId ?? '').isEmpty);
        final myuser = snapshot.data;
        final displayName =
            isWaiting
                ? '로딩 중...'
                : (myuser?.name.isNotEmpty == true ? myuser!.name : '삭제된 사용자');
        final profileUrl =
            (!userMissing && !isWaiting) ? (myuser?.url ?? '') : '';

        return _buildPostItemContent(
          context: context,
          myuser: myuser,
          isWaiting: isWaiting,
          userMissing: userMissing,
          isGuest: isGuest,
          displayName: displayName,
          profileUrl: profileUrl,
        );
      },
    );
  }

  Widget _buildPostItemContent({
    required BuildContext context,
    required MyUser? myuser,
    required bool isWaiting,
    required bool userMissing,
    required bool isGuest,
    required String displayName,
    required String profileUrl,
  }) {
    final List imgUrls =
        (widget.post['imgUrls'] != null && (widget.post['imgUrls'] as List).isNotEmpty)
            ? widget.post['imgUrls'] as List
            : [];

    Widget content = IgnorePointer(
      ignoring: isWaiting,
      child: Column(
        children: [
          // ── fromComments branch ───────────────────────────────────────
          if (widget.post['fromComments'] == true)
            SizedBox(
              width: double.infinity,
              child: Padding(
                padding: EdgeInsets.only(top: 5.h, left: 10.w, right: 10.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                                image:
                                    profileUrl.isNotEmpty
                                        ? ResizeImage(CachedNetworkImageProvider(profileUrl), width: 120)
                                        : const AssetImage('assets/avatar.png')
                                            as ImageProvider,
                                fit: BoxFit.cover,
                              ),
                              shape: const OvalBorder(),
                            ),
                          ),
                        ),
                        horizontalSpace(10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                  : Text(
                                      displayName,
                                      style: TextStyles.abeezee16px400wPblack
                                          .copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                              if (!userMissing && myuser != null && myuser.userId.isNotEmpty)
                                Padding(
                                  padding: EdgeInsets.only(top: 2.h),
                                  child: Text(
                                    '구독자 ${myuser.followerCount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')}명',
                                    style: TextStyle(
                                      color: const Color(0xFF787878),
                                      fontSize: 16.sp,
                                      fontFamily: 'NotoSans',
                                      fontWeight: FontWeight.w400,
                                      height: 1.40.h,
                                      letterSpacing: -0.09.w,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        isGuest
                            ? const SizedBox.shrink()
                            : OtherPostMenu(
                                postId: widget.post['postId'] ?? '',
                                userId: myuser?.userId ?? '',
                                onRunWithLoading: (context, action, success, error) =>
                                    _runWithLoading(
                                      context: context,
                                      action: action,
                                      successMessage: success,
                                      errorMessage: error,
                                    ),
                                displayName: displayName,
                                profileUrl: profileUrl,
                                postData: widget.post,
                              ),
                      ],
                    ),
                    if (widget.post['text'] != null && widget.post['text'].toString().trim().isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 15.h),
                        child: Text(
                          widget.post['text'].toString(),
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
                    verticalSpace(5),
                    if (imgUrls.isNotEmpty)
                      NaturalAspectPageView(
                        imgUrls: imgUrls,
                        pageController: _pageController,
                        explicitWidth: widget.imageWidth,
                      ),
                    verticalSpace(30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Row(children: [GuestPostActions(post: widget.post)]),
                        horizontalSpace(4),
                        Expanded(
                          child: Container(
                            height: 1.h,
                            color: Colors.grey[600],
                          ),
                        ),
                        InkWell(
                          onTap: () => GoRouter.of(context).pop(),
                          child: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // ── normal feed branch ────────────────────────────────────────
          if (widget.post['fromComments'] != true)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 8.h,
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder:
                        (context) => Container(
                          height: MediaQuery.of(context).size.height * 0.95,
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
                            child: GuestComments(post: widget.post),
                          ),
                        ),
                  );
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Avatar
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
                            image:
                                profileUrl.isNotEmpty
                                    ? ResizeImage(CachedNetworkImageProvider(profileUrl), width: 120)
                                    : const AssetImage('assets/avatar.png')
                                        as ImageProvider,
                            fit: BoxFit.cover,
                          ),
                          shape: const OvalBorder(),
                        ),
                      ),
                    ),
                    horizontalSpace(10),

                    // Expanded gives NaturalAspectPageView a bounded width
                    // via LayoutBuilder — no explicitWidth needed here.
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                              : Text(
                                  displayName,
                                  style: TextStyles.abeezee16px400wPblack
                                      .copyWith(fontWeight: FontWeight.bold),
                                ),
                          if (widget.post['text'] != null && widget.post['text'].toString().trim().isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(top: 5.h),
                              child: Builder(
                                builder: (context) {
                                  final String text = widget.post['text'].toString();
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
                              explicitWidth: MediaQuery.of(context).size.width - 82.w,
                            ),
                          verticalSpace(5),
                          Row(children: [GuestPostActions(post: widget.post)]),
                        ],
                      ),
                    ),
                    isGuest
                        ? const SizedBox.shrink()
                        : OtherPostMenu(
                            postId: widget.post['postId'] ?? '',
                            userId: myuser?.userId ?? '',
                            onRunWithLoading: (context, action, success, error) =>
                                _runWithLoading(
                                  context: context,
                                  action: action,
                                  successMessage: success,
                                  errorMessage: error,
                                ),
                            displayName: displayName,
                            profileUrl: profileUrl,
                            postData: widget.post,
                          ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );

    return isWaiting
        ? _PulsingSkeleton(
            child: content,
          )
        : content;
  }
}

class _PulsingSkeleton extends StatefulWidget {
  final Widget child;
  const _PulsingSkeleton({required this.child});

  @override
  State<_PulsingSkeleton> createState() => _PulsingSkeletonState();
}

class _PulsingSkeletonState extends State<_PulsingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 0.85).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: widget.child,
    );
  }
}
