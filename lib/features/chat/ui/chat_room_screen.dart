// screens/chat_screen.dart
import 'dart:typed_data';

import 'package:ecommerece_app/core/helpers/loading_dialog.dart';
import 'package:ecommerece_app/features/chat/domain/chat_room_state_controller.dart';
import 'package:ecommerece_app/features/chat/widgets/chat_input_bar.dart';
import 'package:ecommerece_app/features/chat/widgets/room/blocked_bar.dart';
import 'package:ecommerece_app/features/chat/widgets/room/chat_message_bubble.dart';
import 'package:ecommerece_app/features/chat/widgets/room/chat_room_app_bar.dart';
import 'package:ecommerece_app/features/chat/widgets/room/date_separator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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

    return Scaffold(
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
                        if (state.pickedImageBytes != null) {
                          return Padding(
                            padding: const EdgeInsets.all(12),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.memory(
                                    state.pickedImageBytes as Uint8List,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                    ),
                                    onPressed: controller.clearPickedImage,
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

                            final showDate =
                                index == messages.length - 1 ||
                                !_isSameDay(
                                  messages[index].timestamp,
                                  messages[index + 1].timestamp,
                                );

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
                      onPickImage: controller.pickImage,
                      onSend: () async {
                        if (state.pickedImage != null) {
                          showLoadingDialog(context);
                          try {
                            await controller.sendImageMessage();
                          } finally {
                            if (context.mounted) Navigator.pop(context);
                          }
                        } else {
                          await controller.sendMessage();
                        }
                      },
                    ),
                ],
              ),
    );
  }
}
