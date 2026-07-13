import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/features/chat/domain/chat_controller.dart';
import 'package:ecommerece_app/features/chat/domain/friends_controller.dart';
import 'package:ecommerece_app/features/chat/domain/edit_screen_controller.dart';
import 'package:ecommerece_app/features/chat/models/chat_room_model.dart';
import 'package:ecommerece_app/features/chat/widgets/edit/edit_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EditGroupChatsTab extends ConsumerStatefulWidget {
  const EditGroupChatsTab({super.key});

  @override
  ConsumerState<EditGroupChatsTab> createState() => _EditGroupChatsTabState();
}

class _EditGroupChatsTabState extends ConsumerState<EditGroupChatsTab> {
  Stream<Map<String, int>> _groupOrderStream(String uid) {
    return ref.read(friendsControllerProvider.notifier).getGroupChatsOrderStream(uid);
  }

  Future<void> _reorderGroups(String uid, List<ChatRoomModel> newOrder) async {
    final orderMap = <String, int>{};
    for (int i = 0; i < newOrder.length; i++) {
      orderMap[newOrder[i].id] = i;
    }
    await ref.read(friendsControllerProvider.notifier).reorderGroupChats(uid, orderMap);
  }

  Future<void> _leaveSelected(EditScreenController controller) async {
    final selectedCount = ref.read(editScreenControllerProvider(0)).groupChatsSelected.length;
    if (selectedCount == 0) return;
    
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
                    '$selectedCount개의 그룹채팅방을\n나가시겠습니까?',
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

    if (confirm == true) {
      await controller.leaveSelectedGroupChats();
    }
  }

  late final Stream<Map<String, int>> _groupOrderStreamInstance;
  late final Stream<List<ChatRoomModel>> _chatRoomsStreamInstance;

  @override
  void initState() {
    super.initState();
    final uid = ref.read(editScreenControllerProvider(0).notifier).uid;
    _groupOrderStreamInstance = _groupOrderStream(uid);
    _chatRoomsStreamInstance = ref.read(chatControllerProvider.notifier).getChatRoomsStream();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editScreenControllerProvider(0));
    final controller = ref.read(editScreenControllerProvider(0).notifier);
    final q = state.query;
    final uid = controller.uid;
    final selected = state.groupChatsSelected;

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<Map<String, int>>(
            stream: _groupOrderStreamInstance,
            builder: (ctx, orderSnap) {
              final orderMap = orderSnap.data ?? {};
              return StreamBuilder<List<ChatRoomModel>>(
                stream: _chatRoomsStreamInstance,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox.shrink();
                  }

                  final allGroups =
                      snapshot.data!.where((c) => c.type == 'group').toList();

                  allGroups.sort((a, b) {
                    final aO = orderMap[a.id] ?? 999999;
                    final bO = orderMap[b.id] ?? 999999;
                    return aO.compareTo(bO);
                  });

                  final visibleGroups =
                      q.isEmpty
                          ? allGroups
                          : allGroups
                              .where(
                                (c) =>
                                    c.name.toLowerCase().contains(q) ||
                                    (c.lastMessage ?? '')
                                        .toLowerCase()
                                        .contains(q),
                              )
                              .toList();

                  if (visibleGroups.isEmpty) {
                    return Center(
                      child: Text(
                        q.isNotEmpty ? '검색 결과가 없습니다' : '그룹채팅이 없습니다',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14.sp,
                        ),
                      ),
                    );
                  }

                  final bool canReorder = q.isEmpty;

                  return ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    itemCount: visibleGroups.length,
                    proxyDecorator:
                        (child, index, animation) => Material(
                          color: ColorsManager.primary,
                          child: child,
                        ),
                    onReorder:
                        canReorder
                            ? (oldIdx, newIdx) {
                              final reordered = List<ChatRoomModel>.from(
                                allGroups,
                              );
                              if (newIdx > oldIdx) newIdx--;
                              final item = reordered.removeAt(oldIdx);
                              reordered.insert(newIdx, item);
                              _reorderGroups(uid, reordered);
                            }
                            : (_, __) {},
                    itemBuilder: (ctx, i) {
                      final chat = visibleGroups[i];
                      final isSelected = selected.contains(chat.id);

                      return Container(
                        key: ValueKey(chat.id),
                        color: ColorsManager.primary,
                        child: InkWell(
                          onTap: () => controller.toggleGroupChatSelection(chat.id),
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
                                Container(
                                  width: 44.w,
                                  height: 44.w,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey[200],
                                  ),
                                  child: ClipOval(
                                    child:
                                        (chat.groupImage != null &&
                                                chat.groupImage!.isNotEmpty)
                                            ? CachedNetworkImage(
                                              imageUrl: chat.groupImage!,
                                              fit: BoxFit.cover,
                                              fadeInDuration: Duration.zero,
                                              fadeOutDuration: Duration.zero,
                                              placeholder:
                                                  (context, url) => Container(
                                                    color: Colors.grey[200],
                                                  ),
                                              errorWidget:
                                                  (context, url, error) => Icon(
                                                    Icons.group,
                                                    size: 20.sp,
                                                    color: Colors.grey,
                                                  ),
                                            )
                                            : Icon(
                                              Icons.group,
                                              size: 20.sp,
                                              color: Colors.grey,
                                            ),
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        chat.name,
                                        style: TextStyle(
                                          fontSize: 15.sp,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black,
                                        ),
                                      ),
                                      if (chat.lastMessage?.isNotEmpty == true)
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
                                if (canReorder)
                                  ReorderableDragStartListener(
                                    index: i,
                                    child: Icon(
                                      Icons.drag_handle,
                                      color: Colors.grey[400],
                                      size: 20.sp,
                                    ),
                                  )
                                else
                                  SizedBox(width: 24.w),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        EditBottomBar(
          onDeselectAll: controller.clearGroupChatSelection,
          onLeave: () => _leaveSelected(controller),
          hasSelection: selected.isNotEmpty,
        ),
      ],
    );
  }
}
