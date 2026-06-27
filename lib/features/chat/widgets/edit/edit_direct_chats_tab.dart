import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:ecommerece_app/features/chat/domain/chat_controller.dart';
import 'package:ecommerece_app/features/chat/domain/edit_screen_controller.dart';
import 'package:ecommerece_app/features/chat/models/chat_room_model.dart';
import 'package:ecommerece_app/features/chat/widgets/edit/edit_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EditDirectChatsTab extends ConsumerStatefulWidget {
  const EditDirectChatsTab({super.key});

  @override
  ConsumerState<EditDirectChatsTab> createState() => _EditDirectChatsTabState();
}

class _EditDirectChatsTabState extends ConsumerState<EditDirectChatsTab> {
  final Map<String, MyUser?> _usersCache = {};
  final Set<String> _fetchingIds = {};

  Future<void> _getOtherUser(ChatRoomModel chat) async {
    final uid = ref.read(editScreenControllerProvider(0).notifier).uid;
    final otherId = chat.participants.firstWhere(
      (id) => id != uid,
      orElse: () => '',
    );
    if (otherId.isEmpty) return;

    if (_usersCache.containsKey(otherId) || _fetchingIds.contains(otherId)) {
      return;
    }

    _fetchingIds.add(otherId);

    try {
      MyUser? user = await ref
          .read(chatControllerProvider.notifier)
          .getOtherUserDoc(otherId, chat.type);
      if (mounted) {
        setState(() {
          _usersCache[otherId] = user;
        });
      }
    } catch (_) {
    } finally {
      _fetchingIds.remove(otherId);
    }
  }

  Future<bool?> _showConfirmDialog(String message) {
    return showDialog<bool>(
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
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15.sp, color: Colors.black),
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
  }

  Future<void> _leaveSelected(EditScreenController controller) async {
    final selectedCount =
        ref.read(editScreenControllerProvider(0)).directChatsSelected.length;
    if (selectedCount == 0) return;

    final confirm = await _showConfirmDialog('$selectedCount개의 채팅방을 나가시겠습니까?');

    if (confirm == true) {
      await controller.leaveSelectedDirectChats();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editScreenControllerProvider(0));
    final controller = ref.read(editScreenControllerProvider(0).notifier);
    final q = state.query;
    final uid = controller.uid;
    final selected = state.directChatsSelected;
    final aliases = state.aliases;

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<ChatRoomModel>>(
            stream:
                ref.read(chatControllerProvider.notifier).getChatRoomsStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox.shrink();
              }

              final allChats =
                  snapshot.data!
                      .where(
                        (c) =>
                            (c.type == 'direct' ||
                                c.type == 'seller' ||
                                c.type == 'admin' ||
                                c.type == '') &&
                            !c.deletedBy.contains(uid) &&
                            c.lastMessage != null &&
                            c.lastMessage!.isNotEmpty,
                      )
                      .toList();

              if (allChats.isEmpty) {
                return Center(
                  child: Text(
                    '채팅이 없습니다',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14.sp),
                  ),
                );
              }

              return ListView.builder(
                itemCount: allChats.length,
                itemBuilder: (ctx, i) {
                  final chat = allChats[i];
                  final isSelected = selected.contains(chat.id);

                  final otherId = chat.participants.firstWhere(
                    (id) => id != uid,
                    orElse: () => '',
                  );

                  if (!_usersCache.containsKey(otherId)) {
                    _getOtherUser(chat);
                    return const SizedBox.shrink();
                  }

                  final friend = _usersCache[otherId];
                  final realName = friend?.name ?? chat.name;
                  final avatarUrl = friend?.url ?? '';

                  final displayName = aliases[otherId] ?? realName;
                  final hasAlias =
                      aliases.containsKey(otherId) &&
                      aliases[otherId]!.isNotEmpty;

                  if (q.isNotEmpty &&
                      !displayName.toLowerCase().contains(q) &&
                      !realName.toLowerCase().contains(q) &&
                      !(chat.lastMessage ?? '').toLowerCase().contains(q)) {
                    return const SizedBox.shrink();
                  }

                  return InkWell(
                    onTap: () => controller.toggleDirectChatSelection(chat.id),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 10.h,
                      ),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 22.w,
                            height: 22.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  isSelected
                                      ? Colors.black
                                      : Colors.transparent,
                              border: Border.all(
                                color:
                                    isSelected
                                        ? Colors.black
                                        : Colors.grey[400]!,
                                width: 1.5,
                              ),
                            ),
                            child:
                                isSelected
                                    ? Icon(
                                      Icons.check,
                                      size: 13.sp,
                                      color: Colors.white,
                                    )
                                    : null,
                          ),
                          SizedBox(width: 12.w),
                          CircleAvatar(
                            radius: 22.r,
                            backgroundImage:
                                avatarUrl.isNotEmpty
                                    ? NetworkImage(avatarUrl)
                                    : null,
                            backgroundColor: Colors.grey[200],
                            child:
                                avatarUrl.isEmpty
                                    ? Icon(
                                      Icons.person,
                                      size: 20.sp,
                                      color: Colors.grey,
                                    )
                                    : null,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                                if (hasAlias)
                                  Text(
                                    realName,
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: Colors.grey[400],
                                    ),
                                  )
                                else if (chat.lastMessage?.isNotEmpty == true)
                                  Text(
                                    chat.lastMessage!,
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: Colors.grey[500],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                if (hasAlias &&
                                    chat.lastMessage?.isNotEmpty == true)
                                  Text(
                                    chat.lastMessage!,
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: Colors.grey[500],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          if ((chat.unreadCount[uid] ?? 0) > 0)
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
            },
          ),
        ),
        EditBottomBar(
          onDeselectAll: controller.clearDirectChatSelection,
          onLeave: () => _leaveSelected(controller),
          hasSelection: selected.isNotEmpty,
        ),
      ],
    );
  }
}
