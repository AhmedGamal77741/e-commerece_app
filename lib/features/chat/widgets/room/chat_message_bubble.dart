import 'package:ecommerece_app/core/cache/user_cache.dart';
import 'package:go_router/go_router.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/features/chat/domain/chat_controller.dart';
import 'package:ecommerece_app/features/chat/models/message_model.dart';
import 'package:ecommerece_app/core/providers/firebase_providers.dart';

import 'package:ecommerece_app/features/chat/widgets/chat_post_share.dart';
import 'package:ecommerece_app/features/home/comments.dart';
import 'package:ecommerece_app/core/widgets/safe_network_image.dart';

import 'package:ecommerece_app/features/cart/domain/cart_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ecommerece_app/core/widgets/user_name_header.dart';
import 'package:ecommerece_app/core/widgets/full_screen_image_viewer.dart';

const _kBubbleColor = Color(0xFFEEEEEE);

class MessageBubble extends ConsumerWidget {
  final MessageModel message;
  final bool isMe;
  final String resolvedSenderName;
  final Map<String, String> aliases;
  final VoidCallback onReply;
  final bool interactable;
  final bool isDeleted;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.resolvedSenderName,
    required this.aliases,
    required this.onReply,
    required this.interactable,
    required this.isDeleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onDoubleTap: interactable ? () => _toggleLove(context, ref) : null,
      onLongPress: interactable ? () => _showMessageOptions(context) : null,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: 6.h,
          left: isMe ? 52.w : 0,
          right: isMe ? 0 : 52.w,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isMe) ...[
              _Avatar(senderId: message.senderId, isDeleted: isDeleted),
              SizedBox(width: 6.w),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Padding(
                      padding: EdgeInsets.only(left: 4.w, bottom: 3.h),
                      child: isDeleted
                          ? Text(
                              '삭제된 사용자',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                            )
                          : UserNameHeader(
                              userId: message.senderId,
                              accountName: message.senderName,
                              aliases: aliases,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w500,
                              textColor: Colors.grey[600],
                            ),
                    ),

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (isMe && message.lovedBy.isNotEmpty)
                        _LoveIndicator(
                          count: message.lovedBy.length,
                          lovedByMe: message.lovedBy.contains(
                            ref.watch(currentUserIdProvider),
                          ),
                          onTap:
                              interactable ? () => _toggleLove(context, ref) : null,
                        ),
                      Flexible(
                        child: _BubbleContent(
                          message: message,
                          aliases: aliases,
                        ),
                      ),
                      if (!isMe && message.lovedBy.isNotEmpty)
                        _LoveIndicator(
                          count: message.lovedBy.length,
                          lovedByMe: message.lovedBy.contains(
                            ref.watch(currentUserIdProvider),
                          ),
                          onTap:
                              interactable ? () => _toggleLove(context, ref) : null,
                        ),
                    ],
                  ),

                  Padding(
                    padding: EdgeInsets.only(
                      top: 3.h,
                      left: isMe ? 0 : 4.w,
                      right: isMe ? 4.w : 0,
                    ),
                    child: Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleLove(BuildContext context, WidgetRef ref) => ref.read(chatControllerProvider.notifier).toggleLoveReaction(
    messageId: message.id,
    chatRoomId: message.chatRoomId,
  );

  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 8.h),
              Container(
                width: 36.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 12.h),
              ListTile(
                leading: const Icon(Icons.reply_outlined),
                title: const Text('답장'),
                onTap: () {
                  Navigator.pop(context);
                  onReply();
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy_outlined),
                title: const Text('복사'),
                onTap: () => Navigator.pop(context),
              ),
              if (isMe)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('삭제', style: TextStyle(color: Colors.red)),
                  onTap: () => Navigator.pop(context),
                ),
              SizedBox(height: 8.h),
            ],
          ),
    );
  }

  String _formatTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

class _BubbleContent extends ConsumerWidget {
  final MessageModel message;
  final Map<String, String> aliases;

  const _BubbleContent({required this.message, required this.aliases});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget? replyWidget;
    if (message.replyToMessageId != null &&
        message.replyToMessageId!.isNotEmpty) {
      replyWidget = _ReplyPreview(
        messageId: message.replyToMessageId!,
        chatRoomId: message.chatRoomId,
        aliases: aliases,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: _kBubbleColor,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (replyWidget != null) ...[replyWidget, SizedBox(height: 6.h)],
          if (message.content.isNotEmpty)
            Text(
              message.content,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          if (message.postData != null) ...[
            if (message.content.isNotEmpty) SizedBox(height: 6.h),
            ChatPostShareWidget(
              type: 'post',
              imageUrl: message.postData!['imgUrl'],
              authorName: message.postData!['userId'] ?? '',
              postTitle: message.postData!['text'],
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
                          child: Comments(postId: message.postData!['postId']),
                        ),
                      ),
                );
              },
            ),
          ],
          if (message.productData != null) ...[
            if (message.content.isNotEmpty) SizedBox(height: 6.h),
            ChatPostShareWidget(
              type: 'product',
              imageUrl: message.productData!.imgUrl ?? '',
              postTitle: message.productData!.pricePoints.isNotEmpty
                  ? '${message.productData!.pricePoints[0].price} 원'
                  : '${message.productData!.price} 원',
              authorName: message.productData!.productName,
              onTap: () async {
                bool isSub = await isUserSubscribed();
                if (!context.mounted) return;
                context.pushNamed(
                  Routes.itemDetailsScreen,
                  extra: {
                    'product': message.productData!,
                    'isSub': isSub,
                    'arrivalDay': message.productData!.arrivalDate ?? '',
                  },
                );
              },
            ),
          ],
          if (message.imageUrl != null && message.imageUrl!.isNotEmpty) ...[
            if (message.content.isNotEmpty) SizedBox(height: 6.h),
            GestureDetector(
              onTap: () {
                FullScreenImageViewer.openSingle(context, message.imageUrl!);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SafeNetworkImage(url: message.imageUrl!, fit: BoxFit.cover),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Avatar extends ConsumerWidget {
  final String senderId;
  final bool isDeleted;
  const _Avatar({required this.senderId, required this.isDeleted});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isDeleted) {
      return CircleAvatar(
        radius: 16,
        backgroundColor: Colors.grey[300],
        backgroundImage: const AssetImage('assets/avatar.png'),
      );
    }
    return FutureBuilder(
      future: UserCache.getUser(senderId),
      builder: (_, snap) {
        if (!snap.hasData) {
          return CircleAvatar(radius: 16, backgroundColor: Colors.grey[200]);
        }
        final data = snap.data!.data() as Map<String, dynamic>?;
        final url = data?['url'] as String? ?? '';
        return CircleAvatar(
          radius: 16,
          backgroundColor: Colors.grey[300],
          backgroundImage: url.isNotEmpty ? safeNetworkImageProvider(url) : null,
          child:
              url.isEmpty
                  ? const Icon(Icons.person, size: 16, color: Colors.grey)
                  : null,
        );
      },
    );
  }
}

class _ReplyPreview extends ConsumerWidget {
  final String messageId;
  final String chatRoomId;
  final Map<String, String> aliases;

  const _ReplyPreview({
    required this.messageId,
    required this.chatRoomId,
    required this.aliases,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: ref.read(chatControllerProvider.notifier).getReplyMessage(chatRoomId, messageId),
      builder: (_, snap) {
        if (!snap.hasData || snap.data == null) {
          return const SizedBox.shrink();
        }
        final data = snap.data!;
        final senderId = data['senderId'] as String? ?? '';
        final realSenderName = data['senderName'] as String? ?? '';
        final displayName = aliases[senderId] ?? realSenderName;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 2,
                height: 26,
                color: Colors.grey[500],
                margin: const EdgeInsets.only(right: 6),
              ),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      data['content'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LoveIndicator extends ConsumerWidget {
  final int count;
  final bool lovedByMe;
  final VoidCallback? onTap;

  const _LoveIndicator({
    required this.count,
    required this.lovedByMe,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ImageIcon(
              AssetImage(
                lovedByMe
                    ? "assets/icon=like,status=off (1).png"
                    : "assets/icon=like,status=off.png",
              ),
              size: 16,
              color: lovedByMe ? const Color(0xFF280404) : Colors.grey[500],
            ),
            const SizedBox(width: 2),
            Text(
              count.toString(),
              style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
