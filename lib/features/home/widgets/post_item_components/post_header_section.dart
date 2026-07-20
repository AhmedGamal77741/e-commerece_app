import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:ecommerece_app/features/home/domain/feed_controller.dart';
import 'package:ecommerece_app/features/home/domain/follow_controller.dart';
import 'package:go_router/go_router.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/features/home/widgets/share_dialog.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/core/providers/firebase_providers.dart';
import 'package:ecommerece_app/core/widgets/safe_network_image.dart';

class PostHeaderSection extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAvatar(context),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNameAndNickname(),
              if (!userMissing && myuser != null && myuser!.userId.isNotEmpty)
                _buildFollowerCount(),
            ],
          ),
        ),
        const Spacer(),
        if (!userMissing && myuser != null && !isMyPost)
          _buildActionArea(context, ref),
      ],
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (myuser != null && currentProfileUserId != myuser!.userId) {
          context.pushNamed(
            Routes.profileTabScreen,
            extra: {'userId': myuser!.userId},
          );
        }
      },
      child: ClipOval(
        child: SafeNetworkImage(
          url: profileUrl,
          width: 48.w,
          height: 48.h,
          fit: BoxFit.cover,
          errorWidget: Image.asset(
            'assets/avatar.png',
            width: 48.w,
            height: 48.h,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildNameAndNickname() {
    final String userId = myuser?.userId ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
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
        Consumer(
          builder: (context, ref, _) {
            final syncName = ref.watch(contactNicknameProvider(userId));
            if (syncName == null || syncName.isEmpty) {
              return const SizedBox.shrink();
            }
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: 4.w),
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
            );
          },
        ),
      ],
    );
  }

  Widget _buildFollowerCount() {
    final count = myuser!.followerCount;
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
    if (myuser == null) return const SizedBox.shrink();
    final currentUserId = ref.watch(currentUserIdProvider);
    final bool isFollowing =
        currentUserId.isEmpty
            ? false
            : (ref.watch(isFollowingProvider(myuser!.userId)).value ?? false);

    if (isFollowing) {
      return PopupMenuButton<String>(
        onSelected: (value) async {
          if (value == 'share') {
            showShareDialog(
              context,
              'post',
              'https://www.pang2chocolate.com/comment?postId=$postId',
              postId,
              myuser!.name,
              myuser!.url,
              postData,
              isLoggedIn: ref.read(currentUserIdProvider).isNotEmpty,
            );
          } else if (value == 'unfollow') {
            ref.read(followControllerProvider).toggleFollow(myuser!.userId);
          }
        },
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        itemBuilder:
            (_) => [
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

    if (myuser!.isPrivate) {
      final followRequestAsync = ref.watch(
        hasFollowRequestProvider(myuser!.userId),
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
          final currentUserId = ref.read(currentUserIdProvider);
          if (hasRequest) {
            await ref
                .read(followControllerProvider)
                .cancelFollowRequest(myuser!.userId, currentUserId);
          } else {
            await ref
                .read(followControllerProvider)
                .sendFollowRequest(myuser!.userId, currentUserId);
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
        ref.read(followControllerProvider).toggleFollow(myuser!.userId);
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
