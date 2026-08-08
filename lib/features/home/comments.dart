import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerece_app/features/home/domain/feed_controller.dart';
import 'package:ecommerece_app/features/home/domain/comments_notifier.dart';
import 'package:ecommerece_app/features/home/widgets/comment_input_box.dart';
import 'package:ecommerece_app/core/providers/firebase_providers.dart';
import 'package:ecommerece_app/features/home/widgets/comment_bubble.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Comments extends ConsumerStatefulWidget {
  const Comments({
    super.key,
    required this.postId,
    this.commentId,
    this.canInteract = true,
  });
  
  final String postId;
  final String? commentId;
  final bool canInteract;
  
  @override
  ConsumerState<Comments> createState() => _CommentsState();
}

class _CommentsState extends ConsumerState<Comments> {
  String get currentUserId => ref.watch(currentUserIdProvider);
  bool _hasScrolledToComment = false;
  final Map<String, GlobalKey> _bubbleKeys = {};

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final commentsState = ref.watch(commentsNotifierProvider(widget.postId));

    return commentsState.when(
      data: (state) {
        if (state.postData == null) {
          return Scaffold(
            backgroundColor: theme.colorScheme.surface,
            body: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, color: theme.colorScheme.onSurfaceVariant, size: 48.r),
                    SizedBox(height: 16.h),
                    Text(
                      '삭제되었거나 존재하지 않는 게시글입니다.',
                      style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface),
                    ),
                    SizedBox(height: 24.h),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                      ),
                      child: const Text('닫기'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final postUserId = state.postData!['userId'] ?? '';
        final displayName = state.postAuthor?.name.isNotEmpty == true ? state.postAuthor!.name : '삭제된 사용자';
        final profileUrl = state.postAuthor?.url ?? '';

        return Scaffold(
          backgroundColor: theme.colorScheme.surface,
          body: SafeArea(
            child: Column(
              children: [
                SizedBox(height: 10.h),
                Container(
                  width: 40.w,
                  height: 5.h,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2.5.r),
                  ),
                ),
                SizedBox(height: 10.h),
                Expanded(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final commentsAsync = ref.watch(postCommentsStreamProvider(widget.postId));
                      final comments = commentsAsync.value ?? [];
                      final List<Map<String, dynamic>> chatItems = [];

                      for (final comment in comments) {
                        final dynamic rawTime = comment.createdAt;
                        final DateTime timestamp = rawTime is DateTime
                            ? rawTime
                            : (rawTime is Timestamp ? rawTime.toDate() : DateTime.now());
                        chatItems.add({
                          'id': comment.id,
                          'senderId': comment.userId,
                          'senderName': comment.userName ?? '알 수 없음',
                          'senderImage': comment.userImage ?? '',
                          'content': comment.text,
                          'timestamp': timestamp,
                          'imageUrls': comment.imageUrl != null && comment.imageUrl!.isNotEmpty ? [comment.imageUrl!] : null,
                          'imageRatios': comment.postData != null ? comment.postData!['imageRatios'] as Map? : null,
                          'postData': comment.postData,
                          'productData': comment.productData,
                          'isPost': false,
                        });
                      }

                      final String postText = state.postData!['text'] ?? '';
                      final List imgUrls = state.postData!['imgUrls'] as List? ?? [];
                      final List<String> castedUrls = imgUrls.map((e) => e.toString()).toList();
                      final postTimeRaw = state.postData!['createdAt'];
                      final DateTime postTime = postTimeRaw is DateTime
                          ? postTimeRaw
                          : (postTimeRaw is Timestamp ? postTimeRaw.toDate() : DateTime.now());

                      chatItems.add({
                        'id': widget.postId,
                        'senderId': postUserId,
                        'senderName': displayName,
                        'senderImage': profileUrl,
                        'content': postText,
                        'timestamp': postTime,
                        'imageUrls': castedUrls,
                        'imageRatios': state.postData!['imageRatios'] as Map?,
                        'postData': null,
                        'isPost': true,
                      });

                      final children = List.generate(chatItems.length, (index) {
                        final item = chatItems[index];
                        final isMe = item['senderId'] == currentUserId;
                        final showDate = index == chatItems.length - 1 ||
                            !_isSameDay(item['timestamp'], chatItems[index + 1]['timestamp']);
                        final key = _bubbleKeys.putIfAbsent(item['id'], () => GlobalKey());

                        return Column(
                          key: key,
                          children: [
                            if (showDate) _DateSeparator(date: item['timestamp']),
                            CommentBubble(item: item, isMe: isMe),
                          ],
                        );
                      });

                      if (widget.commentId != null && !_hasScrolledToComment) {
                        final targetKey = _bubbleKeys[widget.commentId];
                        if (targetKey != null) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (targetKey.currentContext != null) {
                              Scrollable.ensureVisible(targetKey.currentContext!, duration: const Duration(milliseconds: 300), alignment: 0.5);
                              _hasScrolledToComment = true;
                            }
                          });
                        }
                      }

                      return ListView(
                        reverse: true,
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                        children: children,
                      );
                    },
                  ),
                ),
                if (widget.canInteract)
                  currentUserId.isEmpty || state.isNormalUser
                      ? Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                          color: theme.colorScheme.surface,
                          child: Row(
                            children: [
                              Icon(Icons.add, color: theme.colorScheme.onSurfaceVariant),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                  child: Text(
                                    '일반 사용자는 댓글을 작성할 수 없습니다.',
                                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : CommentInputBox(
                          onSubmit: (text, {imageFile, imageBytes}) async {
                            try {
                              await ref
                                  .read(commentsNotifierProvider(widget.postId).notifier)
                                  .submitComment(text, imageFile: imageFile, imageBytes: imageBytes);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('댓글 작성에 실패했습니다: $e')),
                                );
                              }
                            }
                          },
                        ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}

class _DateSeparator extends StatelessWidget {
  final DateTime date;
  const _DateSeparator({required this.date});

  String _label() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return '오늘';
    if (d == today.subtract(const Duration(days: 1))) return '어제';
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            _label(),
            style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}
