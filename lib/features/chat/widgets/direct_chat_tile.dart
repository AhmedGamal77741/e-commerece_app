import 'package:ecommerece_app/core/helpers/loading_dialog.dart';
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
    final RenderBox box = tileContext.findRenderObject() as RenderBox;
    final Offset offset = box.localToGlobal(Offset.zero);
    final Size tileSize = box.size;
    final screenWidth = MediaQuery.of(tileContext).size.width;
    final screenHeight = MediaQuery.of(tileContext).size.height;

    const double popupWidth = 200;
    const double popupHeight = 160;

    double left = offset.dx + tileSize.width - popupWidth - 8;
    double top = offset.dy + (tileSize.height / 2) - (popupHeight / 2);

    if (left < 8) left = 8;
    if (left + popupWidth > screenWidth - 8) {
      left = screenWidth - popupWidth - 8;
    }
    if (top < 8) top = 8;
    if (top + popupHeight > screenHeight - 20) {
      top = screenHeight - popupHeight - 20;
    }

    showDialog(
      context: tileContext,
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(tileContext),
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            left: left,
            top: top,
            width: popupWidth,
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 16.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
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
                    SizedBox(height: 10.h),
                    Divider(
                      color: Colors.grey[200],
                      thickness: 1,
                      height: 1,
                    ),
                    _buildMenuOption(
                      label: '차단하기',
                      onTap: () async {
                        final navigator = Navigator.of(tileContext);
                        navigator.pop();
                        if (userId.isEmpty) return;
                        showLoadingDialog(tileContext);
                        await ref
                            .read(feedControllerProvider.notifier)
                            .blockUser(userIdToBlock: userId);
                        navigator.pop();
                      },
                    ),
                    Divider(
                      color: Colors.grey[100],
                      thickness: 1,
                      height: 1,
                      indent: 16.w,
                      endIndent: 16.w,
                    ),
                    _buildMenuOption(
                      label: '나가기',
                      isLast: true,
                      onTap: () async {
                        final navigator = Navigator.of(tileContext);
                        navigator.pop();
                        showLoadingDialog(tileContext);
                        await ref
                            .read(chatControllerProvider.notifier)
                            .softDeleteChatForCurrentUser(chat.id);
                        navigator.pop();
                      },
                    ),
                    SizedBox(height: 8.h),
                  ],
                ),
              ),
            ),
          ),
        ],
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
    final tileKey = GlobalKey();

    return Container(
      key: tileKey,
      margin: const EdgeInsets.only(bottom: 16),
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
          final tileCtx = tileKey.currentContext;
          if (tileCtx == null) return;
          _showChatMenu(tileContext: tileCtx, ref: ref);
        },
        child: Row(
          children: [
            CircleAvatar(
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
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (realName != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          '($realName)',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (chat.lastMessage != null &&
                      chat.lastMessage!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      chat.lastMessage!,
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
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
    );
  }
}
