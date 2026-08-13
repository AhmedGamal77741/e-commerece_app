
import 'package:go_router/go_router.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/features/chat/domain/chat_controller.dart';
import 'package:ecommerece_app/core/providers/firebase_providers.dart';
import 'package:ecommerece_app/features/chat/models/chat_room_model.dart';
import 'package:ecommerece_app/features/home/domain/feed_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ecommerece_app/core/widgets/safe_network_image.dart';
import 'package:ecommerece_app/core/widgets/user_name_header.dart';

class DirectChatTile extends ConsumerWidget {
  final ChatRoomModel chat;
  final String displayName;
  final String? realName;
  final String? avatarUrl;
  final String userId;
  final bool isDeleted;

  const DirectChatTile({
    super.key,
    required this.chat,
    required this.displayName,
    required this.realName,
    required this.avatarUrl,
    required this.userId,
    this.isDeleted = false,
  });

  void _showChatMenu({
    required BuildContext tileContext,
    required WidgetRef ref,
  }) {
    showDialog(
      context: tileContext,
      builder:
          (dialogCtx) => Dialog(
            backgroundColor: Colors.white,
            insetPadding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 24.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Container(
              width: 260.w,
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Text(
                      displayName,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Divider(color: Colors.grey[200], thickness: 1, height: 1),
                  _buildMenuOption(
                    label: '차단하기',
                    onTap: () async {
                      Navigator.pop(dialogCtx);
                      if (userId.isEmpty) return;
                      await ref
                          .read(feedControllerProvider.notifier)
                          .blockUser(userIdToBlock: userId);
                    },
                  ),
                  Divider(color: Colors.grey[200], thickness: 1, height: 1),
                  _buildMenuOption(
                    label: '나가기',
                    labelColor: Colors.red[600],
                    isLast: true,
                    onTap: () async {
                      Navigator.pop(dialogCtx);
                      await ref
                          .read(chatControllerProvider.notifier)
                          .softDeleteChatForCurrentUser(chat.id);
                    },
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildMenuOption({
    required String label,
    required VoidCallback onTap,
    Color? labelColor,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: isLast
          ? BorderRadius.only(
              bottomLeft: Radius.circular(16.r),
              bottomRight: Radius.circular(16.r),
            )
          : BorderRadius.zero,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 14.h),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w500,
            color: labelColor ?? Colors.black87,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserUid = ref.watch(currentUserIdProvider);
    final int unread = chat.unreadCount[currentUserUid] ?? 0;

    return Builder(
      builder: (tileContext) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(25),
                onTap: () {
                  if (userId.isNotEmpty && !isDeleted) {
                    context.pushNamed(
                      Routes.profileTabScreen,
                      extra: {'userId': userId},
                    );
                  }
                },
                child: CircleAvatar(
                  radius: 25,
                  backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                      ? safeNetworkImageProvider(avatarUrl!)
                      : isDeleted
                          ? const AssetImage('assets/avatar.png') as ImageProvider
                          : null,
                  backgroundColor: Colors.grey[200],
                  child: avatarUrl == null && !isDeleted
                      ? Text(
                          displayName.isNotEmpty ? displayName[0] : '?',
                          style: const TextStyle(color: Colors.black),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    context.pushNamed(
                      Routes.chatScreen,
                      pathParameters: {'id': chat.id},
                      extra: {
                        'name': displayName,
                        'isDeleted': isDeleted,
                      },
                    );
                  },
                  onLongPress: () {
                    _showChatMenu(tileContext: tileContext, ref: ref);
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            UserNameHeader(
                              userId: userId,
                              accountName: realName ?? displayName,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            if (chat.lastMessage != null &&
                                chat.lastMessage!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                chat.lastMessage!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[500],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (unread > 0)
                        Image.asset(
                          'assets/notification_dot.png',
                          width: 25.w,
                          height: 25.h,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
