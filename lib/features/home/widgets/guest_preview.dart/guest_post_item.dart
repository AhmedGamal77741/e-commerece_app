import 'package:ecommerece_app/features/home/widgets/guest_preview.dart/guest_comments.dart';
import 'package:go_router/go_router.dart';
import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:ecommerece_app/features/home/domain/feed_controller.dart';
import 'package:ecommerece_app/features/home/profile_tab.dart';
import 'package:ecommerece_app/features/home/widgets/guest_preview.dart/guest_post_actions.dart';
import 'package:ecommerece_app/features/home/widgets/post_item_components/natural_aspect_page_view.dart';
import 'package:ecommerece_app/features/home/widgets/post_item_components/post_menus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ecommerece_app/core/providers/firebase_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
class GuestPostItem extends ConsumerWidget {
  final Map<String, dynamic> post;

  /// Caller-supplied explicit image width.
  /// GuestComments computes this via MediaQuery and passes it in so
  /// NaturalAspectPageView always has the correct pixel width even when
  /// it lives inside a Column/SingleChildScrollView (unbounded width).
  final double? imageWidth;
  final String? currentProfileUserId;

  GuestPostItem({
    super.key,
    required this.post,
    this.imageWidth,
    this.currentProfileUserId,
  });

  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isGuest = ref.watch(currentUserIdProvider).isEmpty;
    final postsProvider = ref.read(feedControllerProvider.notifier);

    Future<void> runWithLoading(
      BuildContext context,
      Future<void> Function() action,
      String successMessage,
      String errorMessage,
    ) async {
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
                    Text('처리 중...'),
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

    final cachedUser = postsProvider.getUser(post['userId']);

    return FutureBuilder<MyUser>(
      future:
          cachedUser != null
              ? Future.value(cachedUser)
              : postsProvider.loadUser(post['userId']),
      initialData: cachedUser,
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

        final List imgUrls =
            (post['imgUrls'] != null && (post['imgUrls'] as List).isNotEmpty)
                ? post['imgUrls'] as List
                : [];

        Widget content = IgnorePointer(
          ignoring: isWaiting,
          child: Column(
            children: [
              // ── fromComments branch ───────────────────────────────────────
              if (post['fromComments'] == true)
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
                                    currentProfileUserId != myuser.userId) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => Scaffold(
                                            body: ProfileTab(
                                              userId: myuser.userId,
                                            ),
                                          ),
                                    ),
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
                                            ? NetworkImage(profileUrl)
                                            : AssetImage('assets/avatar.png')
                                                as ImageProvider,
                                    fit: BoxFit.cover,
                                  ),
                                  shape: OvalBorder(),
                                ),
                              ),
                            ),
                            horizontalSpace(10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  isWaiting
                                      ? Shimmer.fromColors(
                                        baseColor: Colors.grey[300]!,
                                        highlightColor: Colors.grey[100]!,
                                        child: Container(
                                          width: 80.w,
                                          height: 16.h,
                                          color: Colors.white,
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
                                    if (!userMissing && myuser!.userId.isNotEmpty)
                                      StreamBuilder<int>(
                                        stream: ref.watch(followerCountProvider(myuser.userId).future).asStream(),
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
                                          final count = subSnap.data ?? 0;
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
                                ],
                              ),
                            ),
                            const Spacer(),
                            isGuest
                                ? const SizedBox.shrink()
                                : OtherPostMenu(
                                  postId: post['postId'] ?? '',
                                  userId: myuser?.userId ?? '',
                                  onRunWithLoading: runWithLoading,
                                  displayName: displayName,
                                  profileUrl: profileUrl,
                                  postData: post,
                                ),
                          ],
                        ),
                        if (post['text'] != null && post['text'].toString().trim().isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: 15.h),
                            child: Text(
                              post['text'].toString(),
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
                        // imageWidth forwarded from GuestComments so that
                        // NaturalAspectPageView renders at the correct ratio.
                        if (imgUrls.isNotEmpty)
                          NaturalAspectPageView(
                            imgUrls: imgUrls,
                            pageController: _pageController,
                            explicitWidth: imageWidth,
                          ),
                        verticalSpace(30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Row(children: [GuestPostActions(post: post)]),
                            horizontalSpace(4),
                            Expanded(
                              child: Container(
                                height: 1.h,
                                color: Colors.grey[600],
                              ),
                            ),
                            InkWell(
                              onTap: () => GoRouter.of(context).pop(),
                              child: Icon(Icons.close),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              // ── normal feed branch ────────────────────────────────────────
              if (post['fromComments'] != true)
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
                                child: GuestComments(post: post),
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
                                currentProfileUserId != myuser.userId) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => Scaffold(
                                        body: ProfileTab(userId: myuser.userId),
                                      ),
                                ),
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
                                        ? NetworkImage(profileUrl)
                                        : AssetImage('assets/avatar.png')
                                            as ImageProvider,
                                fit: BoxFit.cover,
                              ),
                              shape: OvalBorder(),
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
                                  ? Shimmer.fromColors(
                                    baseColor: Colors.grey[300]!,
                                    highlightColor: Colors.grey[100]!,
                                    child: Container(
                                      width: 80.w,
                                      height: 16.h,
                                      color: Colors.white,
                                      margin: EdgeInsets.only(bottom: 2.h),
                                    ),
                                  )
                                  : Text(
                                    displayName,
                                    style: TextStyles.abeezee16px400wPblack
                                        .copyWith(fontWeight: FontWeight.bold),
                                  ),
                              if (post['text'] != null && post['text'].toString().trim().isNotEmpty)
                                Padding(
                                  padding: EdgeInsets.only(top: 5.h),
                                  child: Builder(
                                    builder: (context) {
                                      final String text = post['text'].toString();
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
                                  // No explicitWidth needed — Expanded above
                                  // already provides a bounded maxWidth.
                                ),
                              verticalSpace(5),
                              Row(children: [GuestPostActions(post: post)]),
                            ],
                          ),
                        ),
                        isGuest
                            ? const SizedBox.shrink()
                            : OtherPostMenu(
                              postId: post['postId'] ?? '',
                              userId: myuser?.userId ?? '',
                              onRunWithLoading: runWithLoading,
                              displayName: displayName,
                              profileUrl: profileUrl,
                              postData: post,
                            ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );

        return isWaiting
            ? Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: content,
            )
            : content;
      },
    );
  }
}
