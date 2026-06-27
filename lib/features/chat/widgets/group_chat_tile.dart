import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerece_app/core/cache/user_cache.dart';
import 'package:ecommerece_app/features/chat/domain/chat_controller.dart';
import 'package:ecommerece_app/features/chat/models/chat_room_model.dart';
import 'package:ecommerece_app/features/chat/ui/chat_room_screen.dart';
import 'package:ecommerece_app/features/home/domain/feed_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class GroupChatTile extends ConsumerWidget {
  final ChatRoomModel chat;

  const GroupChatTile({super.key, required this.chat});

  String get currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  void _showGroupMenu({
    required BuildContext tileContext,
    required WidgetRef ref,
  }) {
    final RenderBox box = tileContext.findRenderObject() as RenderBox;
    final Offset offset = box.localToGlobal(Offset.zero);
    final Size tileSize = box.size;
    final screenWidth = MediaQuery.of(tileContext).size.width;
    final screenHeight = MediaQuery.of(tileContext).size.height;

    final double popupWidth = 220.w;
    final double popupHeight = 210.h;

    double left = offset.dx + tileSize.width - popupWidth - 8.w;
    double top = offset.dy + (tileSize.height / 2) - (popupHeight / 2);

    if (left < 8.w) left = 8.w;
    if (left + popupWidth > screenWidth - 8.w) {
      left = screenWidth - popupWidth - 8.w;
    }
    if (top < 8.h) top = 8.h;
    if (top + popupHeight > screenHeight - 20.h) {
      top = screenHeight - popupHeight - 20.h;
    }

    showDialog(
      context: tileContext,
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      builder:
          (_) => Stack(
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
                          blurRadius: 20.r,
                          spreadRadius: 2.r,
                          offset: Offset(0, 4.h),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: 20.h),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                          child: GroupChatNameText(
                            chat: chat,
                            currentUserId: currentUserId,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22.sp,
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
                          label: '사진 변경',
                          onTap: () async {
                            Navigator.pop(tileContext);
                            await _changeGroupImage(tileContext, ref);
                          },
                        ),
                        Divider(
                          color: Colors.grey[200],
                          thickness: 1,
                          height: 1,
                        ),
                        _buildMenuOption(
                          label: '이름 변경',
                          onTap: () {
                            Navigator.pop(tileContext);
                            _showRenameDialog(tileContext, ref);
                          },
                        ),
                        Divider(
                          color: Colors.grey[200],
                          thickness: 1,
                          height: 1,
                        ),
                        _buildMenuOption(
                          label: '나가기',
                          isLast: true,
                          onTap: () {
                            Navigator.pop(tileContext);
                            _confirmLeaveGroup(tileContext, ref);
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
      borderRadius:
          isLast
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
            fontSize: 18.sp,
            fontWeight: FontWeight.w400,
            color: labelColor ?? Colors.black,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLeaveGroup(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 20.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '채팅방 나가기',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    '"${chat.name}" 채팅방에서 나가시겠습니까?\n나가면 대화 내용이 삭제됩니다.',
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey[700]),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24.r),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                          ),
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(
                            '취소',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[600],
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24.r),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(
                            '나가기',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );

    if (confirm != true) return;
    await ref
        .read(chatControllerProvider.notifier)
        .removeParticipantFromGroup(chat.id, currentUserId);
  }

  Future<void> _changeGroupImage(BuildContext context, WidgetRef ref) async {
    try {
      final newImageUrl =
          await ref
              .read(feedControllerProvider.notifier)
              .uploadImageToFirebaseStorageHome();
      if (newImageUrl.isEmpty) return;

      await ref
          .read(chatControllerProvider.notifier)
          .updateGroupChatImage(chat.id, newImageUrl);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('그룹 사진을 변경했습니다'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('사진 변경 실패: $e')));
      }
    }
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController(text: chat.name);

    showDialog(
      context: context,
      builder:
          (dialogContext) => Dialog(
            backgroundColor: Colors.white,
            insetPadding: EdgeInsets.symmetric(
              horizontal: 24.w,
              vertical: 80.h,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(28.w, 32.h, 28.w, 24.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '이름 변경',
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    '채팅방 이름을 변경합니다',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey[400]),
                  ),
                  SizedBox(height: 24.h),
                  TextField(
                    controller: nameController,
                    maxLength: 40,
                    autofocus: true,
                    style: TextStyle(fontSize: 16.sp, color: Colors.black),
                    decoration: InputDecoration(
                      hintText: '채팅방 이름',
                      hintStyle: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 16.sp,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.grey[300]!,
                          width: 1.2,
                        ),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black, width: 1.5),
                      ),
                      counterStyle: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                  SizedBox(height: 28.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24.r),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 13.h),
                          ),
                          onPressed: () => Navigator.pop(dialogContext),
                          child: Text(
                            '취소',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24.r),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 13.h),
                          ),
                          onPressed: () async {
                            final newName = nameController.text.trim();
                            Navigator.pop(dialogContext);
                            if (newName.isEmpty || newName == chat.name) return;
                            try {
                              await ref
                                  .read(chatControllerProvider.notifier)
                                  .updateGroupChatName(chat.id, newName);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '채팅방 이름을 "$newName"(으)로 변경했습니다',
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('이름 변경 실패: $e')),
                                );
                              }
                            }
                          },
                          child: Text(
                            '변경',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
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
    final tileKey = GlobalKey();
    final int unread = chat.unreadCount[currentUserId] ?? 0;

    return Container(
      key: tileKey,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      ChatScreen(chatRoomId: chat.id, chatRoomName: chat.name),
            ),
          );
        },
        onLongPress: () {
          final tileCtx = tileKey.currentContext;
          if (tileCtx == null) return;
          _showGroupMenu(tileContext: tileCtx, ref: ref);
        },
        child: Row(
          children: [
            Container(
              width: 50.w,
              height: 50.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[200],
              ),
              child: ClipOval(
                child:
                    (chat.groupImage != null && chat.groupImage!.isNotEmpty)
                        ? CachedNetworkImage(
                          imageUrl: chat.groupImage!,
                          fit: BoxFit.cover,
                          fadeInDuration: Duration.zero,
                          fadeOutDuration: Duration.zero,
                          placeholder:
                              (context, url) =>
                                  Container(color: Colors.grey[200]),
                          errorWidget:
                              (context, url, error) => Image.asset(
                                'assets/009.png',
                                fit: BoxFit.cover,
                              ),
                        )
                        : Image.asset('assets/009.png', fit: BoxFit.cover),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GroupChatNameText(
                    chat: chat,
                    currentUserId: currentUserId,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  GroupLastMessage(chat: chat, currentUserId: currentUserId),
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

class GroupLastMessage extends ConsumerWidget {
  final ChatRoomModel chat;
  final String currentUserId;

  const GroupLastMessage({
    super.key,
    required this.chat,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = chat.lastMessage ?? '';
    final senderId = chat.lastMessageSenderId ?? '';
    final senderName = chat.lastMessageSenderName ?? '';

    if (content.isEmpty && senderId.isEmpty) {
      if (chat.participants.isEmpty) return const SizedBox.shrink();
      return Text(
        '${chat.participants.length}명',
        style: TextStyle(fontSize: 12, color: Colors.grey[400]),
      );
    }

    final bool isMe = senderId == currentUserId;
    final String nameLabel = isMe ? '나' : senderName;

    final bool isPhoto = content == '[사진]' || content == '[image]';

    return Row(
      children: [
        if (nameLabel.isNotEmpty)
          Text(
            '$nameLabel: ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        if (isPhoto)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.photo, size: 13, color: Colors.grey[400]),
              const SizedBox(width: 3),
              Text(
                '사진',
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              ),
            ],
          )
        else
          Expanded(child: FadingText(text: content)),
      ],
    );
  }
}

class FadingText extends ConsumerWidget {
  final String text;
  const FadingText({super.key, required this.text});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ShaderMask(
      shaderCallback:
          (bounds) => LinearGradient(
            stops: const [0.0, 0.72, 1.0],
            colors: [
              Colors.grey.shade400,
              Colors.grey.shade400,
              Colors.grey.shade400.withValues(alpha: 0.0),
            ],
          ).createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}

class GroupChatNameText extends ConsumerWidget {
  final ChatRoomModel chat;
  final String currentUserId;
  final TextStyle style;
  final TextAlign? textAlign;

  const GroupChatNameText({
    super.key,
    required this.chat,
    required this.currentUserId,
    required this.style,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (chat.name.trim().isNotEmpty) {
      return Text(
        chat.name,
        style: style,
        textAlign: textAlign,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final otherParticipants =
        chat.participants.where((id) => id != currentUserId).toList();
    final targetIds =
        otherParticipants.isEmpty ? chat.participants : otherParticipants;

    final allCached = targetIds.every(
      (id) => UserCache.getUserCached(id) != null,
    );
    if (allCached) {
      final names =
          targetIds.map((id) {
            final doc = UserCache.getUserCached(id)!;
            if (doc.exists) {
              return doc.get('name') as String? ?? '알 수 없음';
            }
            return '알 수 없음';
          }).toList();
      final nameStr = names.join(', ');
      return Text(
        nameStr,
        style: style,
        textAlign: textAlign,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return FutureBuilder<List<String>>(
      future: Future.wait(
        targetIds.map((id) async {
          try {
            final doc = await UserCache.getUser(id);
            if (doc.exists) {
              return doc.get('name') as String? ?? '알 수 없음';
            }
          } catch (_) {}
          return '알 수 없음';
        }),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Text('...', style: style, textAlign: textAlign);
        }
        final nameStr = snapshot.data!.join(', ');
        return Text(
          nameStr,
          style: style,
          textAlign: textAlign,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}
