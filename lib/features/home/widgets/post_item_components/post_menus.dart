import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ecommerece_app/features/home/domain/feed_controller.dart';
import 'package:ecommerece_app/features/home/domain/follow_controller.dart';
import 'package:ecommerece_app/features/home/widgets/share_dialog.dart';
import 'package:ecommerece_app/core/providers/firebase_providers.dart';

// ── Own-post popup menu ───────────────────────────────────────────────────────

class OwnPostMenu extends ConsumerWidget {
  final String postId;
  final String currentText;
  final VoidCallback onEdit;

  const OwnPostMenu({
    super.key,
    required this.postId,
    required this.currentText,
    required this.onEdit,
  });

  Future<void> _showDeleteDialog(BuildContext context, WidgetRef ref) async {
    await showDialog(
      context: context,
      builder:
          (ctx) => Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '게시글 삭제',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '정말로 이 게시글을 삭제하시겠습니까?',
                    style: TextStyle(fontSize: 16.sp, color: Colors.black),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          '취소',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () async {
                          try {
                            await ref.read(feedControllerProvider.notifier).deletePost(postId: postId);
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                          } catch (e) {
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('삭제 실패: $e'), backgroundColor: Colors.red),
                            );
                          }
                        },
                        child: Text('삭제'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'edit') onEdit();
        if (value == 'delete') _showDeleteDialog(context, ref);
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
    final currentUserId = ref.watch(currentUserIdProvider);
    final followingAsync = ref.watch(followingSetProvider(currentUserId));

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
              isLoggedIn: ref.read(currentUserIdProvider).isNotEmpty,
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
              () => ref.read(feedControllerProvider.notifier).reportUser(reportedUserId: userId, postId: postId),
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
          (_) {
            final isFollowing = followingAsync.value?.contains(userId) ?? false;
            return [
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
            ];
          },
      child: Icon(Icons.more_horiz, color: Colors.black, size: 22.sp),
    );
  }
}
