// screens/chat_screen.dart

import 'package:ecommerece_app/features/chat/models/message_model.dart';
import 'package:ecommerece_app/features/chat/domain/chat_room_state_controller.dart';
import 'package:ecommerece_app/features/chat/widgets/chat_input_bar.dart';
import 'package:ecommerece_app/features/chat/widgets/room/blocked_bar.dart';
import 'package:ecommerece_app/features/chat/widgets/room/chat_message_bubble.dart';
import 'package:ecommerece_app/features/chat/widgets/room/chat_room_app_bar.dart';
import 'package:ecommerece_app/features/chat/widgets/room/date_separator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

const _kBgColor = Color(0xFFF2F2F2);

class ChatScreen extends ConsumerWidget {
  final String chatRoomId;
  final String chatRoomName;
  final bool isDeleted;
  const ChatScreen({
    super.key,
    required this.chatRoomId,
    required this.chatRoomName,
    this.isDeleted = false,
  });

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chatRoomStateControllerProvider(chatRoomId));
    final controller = ref.read(
      chatRoomStateControllerProvider(chatRoomId).notifier,
    );

    return PopScope(
      canPop: kIsWeb,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: _kBgColor,
        appBar: ChatRoomAppBar(
          chatRoomName: chatRoomName,
          chatRoomId: chatRoomId,
        ),
        body:
            state.loadingBlockState
                ? const SizedBox.shrink()
                : Column(
                  children: [
                    // ── Message list ────────────────────────────────────────────
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          if (!state.messagesLoaded) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Colors.black,
                              ),
                            );
                          }
                          final messages = state.messages;
                          if (messages.isEmpty) {
                            return Center(
                              child: Text(
                                '아직 메시지가 없습니다',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                            );
                          }
                          if (state.isPreparingImage) {
                            return Padding(
                              padding: const EdgeInsets.all(12),
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const CircularProgressIndicator(
                                            color: Colors.black54,
                                            strokeWidth: 3,
                                          ),
                                          SizedBox(height: 12.h),
                                          Text(
                                            '이미지 로딩 중...',
                                            style: TextStyle(
                                              color: Colors.black87,
                                              fontSize: 13.sp,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: controller.clearPickedImage,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.6),
                                          shape: BoxShape.circle,
                                        ),
                                        padding: const EdgeInsets.all(6),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          if (state.pickedImageBytes != null) {
                            return Padding(
                              padding: const EdgeInsets.all(12),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.memory(
                                        state.pickedImageBytes as Uint8List,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  if (state.isUploading)
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.5),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 3,
                                            ),
                                            SizedBox(height: 12.h),
                                            Text(
                                              '업로드 중...',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 13.sp,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  if (!state.isUploading)
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: controller.clearPickedImage,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.6),
                                            shape: BoxShape.circle,
                                          ),
                                          padding: const EdgeInsets.all(6),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }
                          return ListView.builder(
                            controller: controller.scrollController,
                            reverse: true,
                            padding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 8.h,
                            ),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final message = messages[index];
                              if (message.deletedBy.contains(
                                controller.currentUserId,
                              )) {
                                return const SizedBox.shrink();
                              }
                              final isMe =
                                  message.senderId == controller.currentUserId;
  
                              // Resolve sender display name using alias
                              final resolvedSenderName =
                                  isMe
                                      ? message.senderName
                                      : (state.aliases[message.senderId] ??
                                          message.senderName);
  
                              // Find previous visible message (older message, above on screen)
                              MessageModel? prevVisibleMessage;
                              for (int i = index + 1; i < messages.length; i++) {
                                if (!messages[i].deletedBy.contains(controller.currentUserId)) {
                                  prevVisibleMessage = messages[i];
                                  break;
                                }
                              }

                              // Find next visible message (newer message, below on screen)
                              MessageModel? nextVisibleMessage;
                              for (int i = index - 1; i >= 0; i--) {
                                if (!messages[i].deletedBy.contains(controller.currentUserId)) {
                                  nextVisibleMessage = messages[i];
                                  break;
                                }
                              }

                              final showDate = prevVisibleMessage == null ||
                                  !_isSameDay(message.timestamp, prevVisibleMessage.timestamp);

                              // Grouping: show avatar/name only on the oldest (top-most) message of a consecutive sequence
                              final bool showAvatarAndName = prevVisibleMessage == null ||
                                  showDate ||
                                  prevVisibleMessage.senderId != message.senderId;

                              // Grouping: show timestamp only on the newest (bottom-most) message of a minute sequence
                              bool showTime = true;
                              if (nextVisibleMessage != null) {
                                final isSameSenderAsNext = nextVisibleMessage.senderId == message.senderId;
                                final isSameMinuteAsNext = nextVisibleMessage.timestamp.hour == message.timestamp.hour &&
                                    nextVisibleMessage.timestamp.minute == message.timestamp.minute;
                                final isSameDateAsNext = _isSameDay(message.timestamp, nextVisibleMessage.timestamp);

                                if (isSameSenderAsNext && isSameMinuteAsNext && isSameDateAsNext) {
                                  showTime = false;
                                }
                              }
  
                              return Column(
                                children: [
                                  if (showDate)
                                    DateSeparator(date: message.timestamp),
                                  MessageBubble(
                                    message: message,
                                    isMe: isMe,
                                    resolvedSenderName: resolvedSenderName,
                                    aliases: state.aliases,
                                    onReply:
                                        () =>
                                            controller.setReplyToMessage(message),
                                    interactable:
                                        !(state.blocked || state.isBlocked) &&
                                        !isDeleted,
                                    isDeleted: isDeleted,
                                    showAvatarAndName: showAvatarAndName,
                                    showTime: showTime,
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
  
                    // ── Reply preview strip ─────────────────────────────────────
                    if (state.replyToMessage != null)
                      Container(
                        color: const Color(0xFFE2E2E2),
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 8.h,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 3,
                              height: 34.h,
                              decoration: BoxDecoration(
                                color: Colors.grey[600],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    // Show alias for replied-to sender too
                                    state.aliases[state
                                            .replyToMessage!
                                            .senderId] ??
                                        state.replyToMessage!.senderName,
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  Text(
                                    state.replyToMessage!.content,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => controller.setReplyToMessage(null),
                              child: Icon(
                                Icons.close,
                                size: 18.sp,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
  
                    // ── Input bar ───────────────────────────────────────────────
                    if (state.blocked || state.isBlocked)
                      BlockedBar(
                        blocked: state.blocked,
                        isBlocked: state.isBlocked,
                        chatRoomId: chatRoomId,
                        currentUserId: controller.currentUserId,
                        onUnblock: controller.unblockUser,
                      )
                    else if (isDeleted || state.roomDeleted)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 20.h),
                        color: _kBgColor,
                        alignment: Alignment.center,
                        child: Text(
                          '대화에 더 이상 참여할 수 없습니다.',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14.sp,
                          ),
                        ),
                      )
                    else
                      InputBar(
                        controller: controller.messageController,
                        pickedImage: state.pickedImage,
                        isUploading: state.isUploading || state.isPreparingImage,
                        onPickImage: controller.pickImage,
                        onSend: () async {
                          if (state.pickedImage != null) {
                            await controller.sendImageMessage();
                          } else {
                            await controller.sendMessage();
                          }
                        },
                      ),
                  ],
                ),
        ),
    );
  }
}
