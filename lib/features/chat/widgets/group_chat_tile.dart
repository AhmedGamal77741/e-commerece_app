import 'package:ecommerece_app/core/widgets/safe_network_image.dart';
import 'package:ecommerece_app/core/cache/user_cache.dart';
import 'package:go_router/go_router.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/features/chat/domain/chat_controller.dart';
import 'package:ecommerece_app/features/chat/domain/friends_controller.dart';
import 'package:ecommerece_app/features/chat/models/chat_room_model.dart';
import 'package:ecommerece_app/features/chat/widgets/friends/friends_modals.dart';
import 'package:ecommerece_app/core/providers/firebase_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:image_picker/image_picker.dart';
import 'package:ecommerece_app/core/helpers/image_upload_helper.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupChatTile extends ConsumerWidget {
  final ChatRoomModel chat;

  const GroupChatTile({super.key, required this.chat});

  void _showGroupMenu({
    required BuildContext tileContext,
    required WidgetRef ref,
  }) {
    final currentUserId = ref.read(currentUserIdProvider);

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
                    child: GroupChatNameText(
                      chat: chat,
                      currentUserId: currentUserId,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Divider(color: Colors.grey[200], thickness: 1, height: 1),
                  _buildMenuOption(
                    label: '친구 초대',
                    onTap: () {
                      Navigator.pop(dialogCtx);
                      final aliases =
                          ref.read(aliasesProvider).value ??
                          <String, String>{};
                      showInviteFriendsDialog(
                        context: tileContext,
                        ref: ref,
                        chat: chat,
                        aliases: aliases,
                      );
                    },
                  ),
                  Divider(color: Colors.grey[200], thickness: 1, height: 1),
                  _buildMenuOption(
                    label: '사진 변경',
                    onTap: () async {
                      Navigator.pop(dialogCtx);
                      await _changeGroupImage(tileContext, ref);
                    },
                  ),
                  Divider(color: Colors.grey[200], thickness: 1, height: 1),
                  _buildMenuOption(
                    label: '이름 변경',
                    onTap: () {
                      Navigator.pop(dialogCtx);
                      _showRenameDialog(tileContext, ref);
                    },
                  ),
                  Divider(color: Colors.grey[200], thickness: 1, height: 1),
                  _buildMenuOption(
                    label: '나가기',
                    labelColor: Colors.red[600],
                    isLast: true,
                    onTap: () {
                      Navigator.pop(dialogCtx);
                      _confirmLeaveGroup(tileContext, ref);
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
    final currentUserId = ref.read(currentUserIdProvider);
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
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (ctx) => const PopScope(
                canPop: false,
                child: Center(
                  child: Card(
                    color: Colors.white,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.black),
                          SizedBox(width: 16),
                          Text(
                            '사진 변환 및 업로드 중...',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
        );
      }

      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) throw Exception("User not logged in");

      final rawBytes = await image.readAsBytes();
      final previewBytes = await ImageUploadHelper.preparePreviewBytes(
        rawBytes,
        image.name,
      );

      final mimeType = ImageUploadHelper.lookupMimeType(image.name);

      final ext = mimeType == 'image/png' ? 'png' : 'jpg';
      final fileName =
          'group_chat_${DateTime.now().millisecondsSinceEpoch}_$currentUserId.$ext';

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('uploads')
          .child(fileName);

      final uploadTask = storageRef.putData(
        previewBytes,
        SettableMetadata(contentType: mimeType),
      );

      final snapshot = await uploadTask;
      final newImageUrl = await snapshot.ref.getDownloadURL();

      await ref
          .read(chatControllerProvider.notifier)
          .updateGroupChatImage(chat.id, newImageUrl);

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // pop loading modal
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('그룹 사진을 변경했습니다'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (_) {}
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
    final currentUserId = ref.watch(currentUserIdProvider);
    final int unread = chat.unreadCount[currentUserId] ?? 0;

    return Builder(
      builder: (tileContext) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              context.pushNamed(
                Routes.chatScreen,
                pathParameters: {'id': chat.id},
                extra: {'name': chat.name},
              );
            },
            onLongPress: () {
              _showGroupMenu(tileContext: tileContext, ref: ref);
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
                        ? SafeNetworkImage(
                            url: chat.groupImage!,
                            width: 50.w,
                            height: 50.w,
                            fit: BoxFit.cover,
                            fadeInDuration: Duration.zero,
                            fadeOutDuration: Duration.zero,
                            placeholder: Container(color: Colors.grey[200]),
                            errorWidget: Image.asset(
                              'assets/009.png',
                              fit: BoxFit.cover,
                              cacheWidth: 150,
                            ),
                          )
                        : Image.asset(
                            'assets/009.png',
                            fit: BoxFit.cover,
                            cacheWidth: 150,
                          ),
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
      },
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

class GroupChatNameText extends ConsumerStatefulWidget {
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
  ConsumerState<GroupChatNameText> createState() => _GroupChatNameTextState();
}

class _GroupChatNameTextState extends ConsumerState<GroupChatNameText> {
  Future<List<String>>? _fetchFuture;
  List<String>? _resolvedNames;

  @override
  void initState() {
    super.initState();
    _initFuture();
  }

  @override
  void didUpdateWidget(GroupChatNameText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.chat.participants.length != oldWidget.chat.participants.length ||
        !widget.chat.participants.every((id) => oldWidget.chat.participants.contains(id))) {
      _resolvedNames = null;
      _initFuture();
    }
  }

  void _initFuture() {
    if (widget.chat.name.trim().isNotEmpty) return;

    final otherParticipants =
        widget.chat.participants.where((id) => id != widget.currentUserId).toList();
    final targetIds =
        otherParticipants.isEmpty ? widget.chat.participants : otherParticipants;

    final allCached = targetIds.every(
      (id) => UserCache.getUserCached(id) != null,
    );

    if (allCached) {
      _resolvedNames = targetIds.map((id) {
        final doc = UserCache.getUserCached(id)!;
        if (doc.exists) {
          return doc.get('name') as String? ?? '알 수 없음';
        }
        return '알 수 없음';
      }).toList();
    } else {
      _fetchFuture = Future.wait(
        targetIds.map((id) async {
          try {
            final doc = await UserCache.getUser(id);
            if (doc.exists) {
              return doc.get('name') as String? ?? '알 수 없음';
            }
          } catch (_) {}
          return '알 수 없음';
        }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.chat.name.trim().isNotEmpty) {
      return Text(
        widget.chat.name,
        style: widget.style,
        textAlign: widget.textAlign,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    if (_resolvedNames != null) {
      return Text(
        _resolvedNames!.join(', '),
        style: widget.style,
        textAlign: widget.textAlign,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return FutureBuilder<List<String>>(
      future: _fetchFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          _resolvedNames = snapshot.data;
          return Text(
            _resolvedNames!.join(', '),
            style: widget.style,
            textAlign: widget.textAlign,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }
        return Text('...', style: widget.style, textAlign: widget.textAlign);
      },
    );
  }
}
