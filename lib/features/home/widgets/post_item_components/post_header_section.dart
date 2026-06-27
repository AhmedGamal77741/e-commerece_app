import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:ecommerece_app/features/chat/services/contacts_service.dart';
import 'package:ecommerece_app/features/home/domain/feed_controller.dart';
import 'package:ecommerece_app/features/home/domain/follow_controller.dart';
import 'package:ecommerece_app/features/home/profile_tab.dart';
import 'package:ecommerece_app/features/home/widgets/share_dialog.dart';
import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
        horizontalSpace(10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNameAndNickname(),
              if (!userMissing && myuser!.userId.isNotEmpty)
                _buildFollowerCount(ref),
            ],
          ),
        ),
        Spacer(),
        if (!userMissing && !isMyPost) _buildActionArea(context, ref),
      ],
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return InkWell(
      onTap: () {
        if (myuser != null && currentProfileUserId != myuser!.userId) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Scaffold(body: ProfileTab(userId: myuser!.userId)),
            ),
          );
        }
      },
      child: Container(
        width: 48.w,
        height: 48.h,
        decoration: ShapeDecoration(
          image: DecorationImage(
            image: profileUrl.isNotEmpty
                ? NetworkImage(profileUrl)
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
            : Flexible(
                child: Text(
                  displayName,
                  style: TextStyles.abeezee16px400wPblack.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
        horizontalSpace(4),
        FutureBuilder<String?>(
          future: ContactService().getContactNickname(myuser == null ? "" : myuser!.userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox.shrink();
            }
            if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
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
        ),
      ],
    );
  }

  Widget _buildFollowerCount(WidgetRef ref) {
    final followerCountAsync = ref.watch(followerCountProvider(myuser!.userId));
    
    return followerCountAsync.when(
      data: (count) {
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
      },
      loading: () => SizedBox(height: 16.sp),
      error: (_, __) => Text('구독자 오류', style: TextStyle(color: Colors.red, fontSize: 16.sp)),
    );
  }

  Widget _buildActionArea(BuildContext context, WidgetRef ref) {
    final followingAsync = ref.watch(isFollowingProvider(myuser!.userId));
    final isFollowing = followingAsync.value ?? false;

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
            );
          } else if (value == 'unfollow') {
            ref.read(followControllerProvider).toggleFollow(myuser!.userId);
          }
        },
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        itemBuilder: (BuildContext context) => [
          PopupMenuItem<String>(
            value: 'share',
            child: Text('공유', style: TextStyle(color: Colors.black, fontSize: 13.sp)),
          ),
          PopupMenuItem<String>(
            value: 'unfollow',
            child: Text('구독 취소', style: TextStyle(color: Colors.black, fontSize: 13.sp)),
          ),
        ],
        child: Icon(Icons.more_horiz, color: Colors.black, size: 22.sp),
      );
    }

    if (myuser!.isPrivate) {
      final followRequestAsync = ref.watch(hasFollowRequestProvider(myuser!.userId));
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
          final currentUserId = FirebaseAuth.instance.currentUser?.uid;
          if (currentUserId == null) return;
          if (hasRequest) {
            await ref.read(followControllerProvider).cancelFollowRequest(myuser!.userId, currentUserId);
          } else {
            await ref.read(followControllerProvider).sendFollowRequest(myuser!.userId, currentUserId);
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
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
