import 'package:ecommerece_app/features/home/widgets/share_dialog.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/features/home/domain/follow_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerece_app/features/home/domain/feed_controller.dart';
class OwnPostMenu extends ConsumerWidget {
  final String postId;
  final String currentText;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const OwnPostMenu({
    super.key,
    required this.postId,
    required this.currentText,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'edit') onEdit();
        if (value == 'delete') onDelete();
      },
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder:
          (_) => [
            PopupMenuItem<String>(
              value: 'edit',
              child: Text(
                '수정하기',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14.sp,
                  fontFamily: 'NotoSans',
                ),
              ),
            ),
            PopupMenuItem<String>(
              value: 'delete',
              child: Text(
                '삭제하기',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14.sp,
                  fontFamily: 'NotoSans',
                ),
              ),
            ),
          ],
      child: Icon(Icons.more_horiz, color: Colors.black, size: 22.sp),
    );
  }
}

// ── Other user's post popup menu ──────────────────────────────────────────────

class OtherPostMenu extends ConsumerWidget {
  final String postId;
  final String userId;
  final Future<void> Function(
    BuildContext,
    Future<void> Function(),
    String,
    String,
  )
  onRunWithLoading;
  final String displayName;
  final String profileUrl;
  final Map<String, dynamic> postData;

  const OtherPostMenu({
    super.key,
    required this.postId,
    required this.userId,
    required this.onRunWithLoading,
    required this.displayName,
    required this.profileUrl,
    required this.postData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .doc(currentUid)
              .collection('following')
              .doc(userId.isEmpty ? 's' : userId)
              .snapshots(),
      builder: (context, asyncSnapshot) {
        final isFollowing = asyncSnapshot.hasData && asyncSnapshot.data!.exists;

        return PopupMenuButton<String>(
          onSelected: (value) async {
            switch (value) {
              case 'share':
                showShareDialog(
                  context,
                  'post',
                  'https://www.pang2chocolate.com/comment?postId=$postId',
                  postId,
                  displayName,
                  profileUrl,
                  postData,
                );
                break;
              case 'follow_unfollow':
                await ref.read(followControllerProvider).toggleFollow(userId);
                break;
              case 'block':
                await onRunWithLoading(
                  context,
                  () => ref.read(feedControllerProvider.notifier).blockUser(userIdToBlock: userId),
                  '차단되었습니다.',
                  '오류 발생',
                );
                break;
              case 'report':
                await onRunWithLoading(
                  context,
                  () async =>
                      ref.read(feedControllerProvider.notifier).reportUser(reportedUserId: userId, postId: postId),
                  '신고가 접수되었습니다.',
                  '신고 처리 중 오류가 발생했습니다',
                );
                break;
            }
          },
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          itemBuilder:
              (_) => [
                PopupMenuItem<String>(
                  value: 'share',
                  child: Text(
                    '공유',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14.sp,
                      fontFamily: 'NotoSans',
                    ),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'follow_unfollow',
                  child: Text(
                    isFollowing ? '구독취소' : '구독하기',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14.sp,
                      fontFamily: 'NotoSans',
                    ),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'block',
                  child: Text(
                    '차단',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14.sp,
                      fontFamily: 'NotoSans',
                    ),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'report',
                  child: Text(
                    '신고하기',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14.sp,
                      fontFamily: 'NotoSans',
                    ),
                  ),
                ),
              ],
          child: Icon(Icons.more_horiz, color: Colors.black, size: 22.sp),
        );
      },
    );
  }
}
