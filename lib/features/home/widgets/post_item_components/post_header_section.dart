import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:ecommerece_app/features/chat/services/contacts_service.dart';
import 'package:ecommerece_app/features/home/domain/feed_controller.dart';
import 'package:ecommerece_app/features/home/domain/follow_controller.dart';
import 'package:go_router/go_router.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/features/home/widgets/share_dialog.dart';
import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/core/providers/firebase_providers.dart';

class PostHeaderSection extends ConsumerStatefulWidget {
  final MyUser? myuser;
  final String displayName;
  final String profileUrl;
  final bool isWaiting;
  final bool userMissing;
  final bool isMyPost;
  final String? currentProfileUserId;
  final String postId;
  final Map<String, dynamic> postData;

  const PostHeaderSection({
    super.key,
    required this.myuser,
    required this.displayName,
    required this.profileUrl,
    required this.isWaiting,
    required this.userMissing,
    required this.isMyPost,
    this.currentProfileUserId,
    required this.postId,
    required this.postData,
  });

  @override
  ConsumerState<PostHeaderSection> createState() => _PostHeaderSectionState();
}

class _PostHeaderSectionState extends ConsumerState<PostHeaderSection> {
  String? _cachedUserId;
  Future<String?>? _nicknameFuture;

  Future<String?> _getNickname(String userId) {
    if (userId == _cachedUserId && _nicknameFuture != null)
      return _nicknameFuture!;
    _cachedUserId = userId;
    _nicknameFuture = ContactService().getContactNickname(userId);
    return _nicknameFuture!;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAvatar(context),
        horizontalSpace(10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNameAndNickname(),
              if (!widget.userMissing &&
                  widget.myuser != null &&
                  widget.myuser!.userId.isNotEmpty)
                _buildFollowerCount(ref),
            ],
          ),
        ),
        const Spacer(),
        if (!widget.userMissing && !widget.isMyPost)
          _buildActionArea(context, ref),
      ],
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return InkWell(
      onTap: () {
        if (widget.myuser != null &&
            widget.currentProfileUserId != widget.myuser!.userId) {
          context.pushNamed(
            Routes.profileTabScreen,
            extra: {'userId': widget.myuser!.userId},
          );
        }
      },
      child: Container(
        width: 48.w,
        height: 48.h,
        decoration: ShapeDecoration(
          image: DecorationImage(
            image:
                widget.profileUrl.isNotEmpty
                    ? ResizeImage(
                      CachedNetworkImageProvider(widget.profileUrl),
                      width: 120,
                    )
                    : const AssetImage('assets/avatar.png') as ImageProvider,
            fit: BoxFit.cover,
          ),
          shape: const OvalBorder(),
        ),
      ),
    );
  }

  Widget _buildNameAndNickname() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        widget.isWaiting
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
                widget.displayName,
                style: TextStyles.abeezee16px400wPblack.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        horizontalSpace(4),
        Builder(
          builder: (context) {
            final String userId =
                widget.myuser == null ? "" : widget.myuser!.userId;
            final contactService = ContactService();
            if (contactService.isNameMapLoaded()) {
              final syncName = contactService.getContactNicknameSync(userId);
              if (syncName != null && syncName.isNotEmpty) {
                return Flexible(
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
                );
              }
              return const SizedBox.shrink();
            }
            return FutureBuilder<String?>(
              future: _getNickname(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink();
                }
                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data == null) {
                  return const SizedBox.shrink();
                }
                final nickname = snapshot.data!;
                return Flexible(
                  child: Text(
                    '@$nickname',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildFollowerCount(WidgetRef ref) {
    final count = widget.myuser!.followerCount;
    final formatted = count.toString().replaceAllMapped(
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

  Widget _buildActionArea(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(currentUserIdProvider);
    final bool isFollowing =
        currentUserId.isEmpty
            ? false
            : (ref
                    .watch(followingSetProvider(currentUserId))
                    .value
                    ?.contains(widget.myuser!.userId) ??
                false);

    if (isFollowing) {
      return PopupMenuButton<String>(
        onSelected: (value) async {
          if (value == 'share') {
            showShareDialog(
              context,
              'post',
              'https://www.pang2chocolate.com/comment?postId=${widget.postId}',
              widget.postId,
              widget.myuser!.name,
              widget.myuser!.url,
              widget.postData,
              isLoggedIn: ref.read(currentUserIdProvider).isNotEmpty,
            );
          } else if (value == 'unfollow') {
            ref
                .read(followControllerProvider)
                .toggleFollow(widget.myuser!.userId);
          }
        },
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        itemBuilder:
            (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'share',
                child: Text(
                  '공유',
                  style: TextStyle(color: Colors.black, fontSize: 13.sp),
                ),
              ),
              PopupMenuItem<String>(
                value: 'unfollow',
                child: Text(
                  '구독 취소',
                  style: TextStyle(color: Colors.black, fontSize: 13.sp),
                ),
              ),
            ],
        child: Icon(Icons.more_horiz, color: Colors.black, size: 22.sp),
      );
    }

    if (widget.myuser!.isPrivate) {
      final followRequestAsync = ref.watch(
        hasFollowRequestProvider(widget.myuser!.userId),
      );
      final hasRequest = followRequestAsync.value ?? false;

      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: hasRequest ? Colors.grey[300] : Colors.black,
          foregroundColor: hasRequest ? Colors.black : Colors.white,
          minimumSize: Size(35.w, 33.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: () async {
          final currentUserId = ref.watch(currentUserIdProvider);
          if (hasRequest) {
            await ref
                .read(followControllerProvider)
                .cancelFollowRequest(widget.myuser!.userId, currentUserId);
          } else {
            await ref
                .read(followControllerProvider)
                .sendFollowRequest(widget.myuser!.userId, currentUserId);
          }
        },
        child: Text(
          hasRequest ? '요청 취소' : '구독 신청',
          style: TextStyle(
            fontSize: 12.sp,
            fontFamily: 'NotoSans',
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        minimumSize: Size(40.w, 28.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      onPressed: () async {
        ref.read(followControllerProvider).toggleFollow(widget.myuser!.userId);
      },
      child: Text(
        '구독',
        style: TextStyle(
          fontSize: 12.sp,
          fontFamily: 'NotoSans',
          fontWeight: FontWeight.w500,
        ),
      ),
    );
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
      opacity: Tween<double>(
        begin: 0.35,
        end: 0.85,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: widget.child,
    );
  }
}
