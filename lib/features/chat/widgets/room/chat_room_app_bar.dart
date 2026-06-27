import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ecommerece_app/features/chat/domain/chat_room_state_controller.dart';
import 'package:ecommerece_app/core/cache/user_cache.dart';

class ChatRoomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String chatRoomName;
  final String chatRoomId;

  const ChatRoomAppBar({
    super.key,
    required this.chatRoomName,
    required this.chatRoomId,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chatRoomStateControllerProvider(chatRoomId));

    String resolveDisplayName(String userId, String realName) {
      return state.aliases[userId] ?? realName;
    }

    String getAppBarTitle() {
      if (!state.isGroup && state.otherUserId.isNotEmpty) {
        return state.aliases[state.otherUserId] ?? chatRoomName;
      }
      return chatRoomName;
    }

    Future<List<Map<String, dynamic>>> fetchMemberDetails(List<String> ids) async {
      final currentUserId = ref.read(chatRoomStateControllerProvider(chatRoomId).notifier).currentUserId;
      final results = await Future.wait(
        ids.map((id) async {
          try {
            final doc = await UserCache.getUser(id);
            if (doc.exists) {
              final data = doc.data() as Map<String, dynamic>?;
              return {
                'id': id,
                'name': data?['name'] as String? ?? '알 수 없음',
                'url': data?['url'] as String? ?? '',
              };
            }
          } catch (_) {}
          return {'id': id, 'name': '알 수 없음', 'url': ''};
        }),
      );
      results.sort(
        (a, b) =>
            a['id'] == currentUserId
                ? -1
                : b['id'] == currentUserId
                ? 1
                : 0,
      );
      return results;
    }

    void showMembersDialog() {
      if (state.chatRoom == null) return;
      final currentUserId = ref.read(chatRoomStateControllerProvider(chatRoomId).notifier).currentUserId;
      
      showDialog(
        context: context,
        builder:
            (ctx) => Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
              ),
              insetPadding: EdgeInsets.symmetric(
                horizontal: 32.w,
                vertical: 80.h,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 12.h),
                    child: Row(
                      children: [
                        Text(
                          '멤버',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${state.chatRoom!.participants.length}',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: Colors.grey[100], height: 1),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: 360.h),
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: fetchMemberDetails(state.chatRoom!.participants),
                      builder: (context, snap) {
                        if (!snap.hasData) {
                          return Padding(
                            padding: EdgeInsets.all(32.h),
                            child: const SizedBox.shrink(),
                          );
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          itemCount: snap.data!.length,
                          separatorBuilder:
                              (_, __) =>
                                  Divider(color: Colors.grey[100], height: 1),
                          itemBuilder: (_, i) {
                            final m = snap.data![i];
                            final isMe = m['id'] == currentUserId;
                            final url = m['url'] as String? ?? '';
                            final realName = m['name'] as String? ?? '알 수 없음';
                            final displayName =
                                isMe
                                    ? '$realName (나)'
                                    : resolveDisplayName(
                                      m['id'] as String,
                                      realName,
                                    );
                            final hasAlias =
                                !isMe &&
                                state.aliases.containsKey(m['id']) &&
                                state.aliases[m['id']]!.isNotEmpty;

                            return Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 20.w,
                                vertical: 10.h,
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20.r,
                                    backgroundImage:
                                        url.isNotEmpty ? NetworkImage(url) : null,
                                    backgroundColor: Colors.grey[200],
                                    child:
                                        url.isEmpty
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          displayName,
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight:
                                                isMe
                                                    ? FontWeight.w600
                                                    : FontWeight.w400,
                                          ),
                                        ),
                                        if (hasAlias)
                                          Text(
                                            realName,
                                            style: TextStyle(
                                              fontSize: 11.sp,
                                              color: Colors.grey[400],
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
                      },
                    ),
                  ),
                  Divider(color: Colors.grey[100], height: 1),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      '닫기',
                      style: TextStyle(color: Colors.black, fontSize: 14.sp),
                    ),
                  ),
                  SizedBox(height: 4.h),
                ],
              ),
            ),
      );
    }

    Widget buildGroupTitleWidget() {
      final currentUserId = ref.read(chatRoomStateControllerProvider(chatRoomId).notifier).currentUserId;

      if (!state.isGroup) {
        return Text(
          getAppBarTitle(),
          style: TextStyle(
            color: Colors.black,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        );
      }

      if (chatRoomName.trim().isNotEmpty) {
        return Text(
          chatRoomName,
          style: TextStyle(
            color: Colors.black,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        );
      }

      if (state.chatRoom == null) {
        return Text(
          '...',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        );
      }

      final allCached = state.chatRoom!.participants.every(
        (id) => UserCache.getUserCached(id) != null,
      );
      if (allCached) {
        final otherNames =
            state.chatRoom!.participants.where((id) => id != currentUserId).map((id) {
              final doc = UserCache.getUserCached(id)!;
              final name =
                  doc.exists
                      ? (doc.get('name') as String? ?? '알 수 없음')
                      : '알 수 없음';
              return resolveDisplayName(id, name);
            }).toList();
        final targetNames = otherNames.isEmpty ? ['나'] : otherNames;
        return Text(
          targetNames.join(', '),
          style: TextStyle(
            color: Colors.black,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      }

      return FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchMemberDetails(state.chatRoom!.participants),
        builder: (context, snap) {
          if (!snap.hasData) {
            return Text(
              '...',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            );
          }
          final otherNames =
              snap.data!
                  .where((m) => m['id'] != currentUserId)
                  .map(
                    (m) => resolveDisplayName(
                      m['id'] as String,
                      m['name'] as String? ?? '알 수 없음',
                    ),
                  )
                  .toList();
          final targetNames = otherNames.isEmpty ? ['나'] : otherNames;
          return Text(
            targetNames.join(', '),
            style: TextStyle(
              color: Colors.black,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        },
      );
    }

    Widget buildGroupSubtitle() {
      if (state.chatRoom == null) return const SizedBox.shrink();
      final currentUserId = ref.read(chatRoomStateControllerProvider(chatRoomId).notifier).currentUserId;

      final allCached = state.chatRoom!.participants.every(
        (id) => UserCache.getUserCached(id) != null,
      );
      if (allCached) {
        final names =
            state.chatRoom!.participants.map((id) {
              final isMe = id == currentUserId;
              if (isMe) return '나';
              final doc = UserCache.getUserCached(id)!;
              final name =
                  doc.exists
                      ? (doc.get('name') as String? ?? '알 수 없음')
                      : '알 수 없음';
              return resolveDisplayName(id, name);
            }).toList();

        final mi = names.indexOf('나');
        if (mi > 0) {
          names.removeAt(mi);
          names.insert(0, '나');
        }

        final subtitle =
            names.length <= 2
                ? names.join(', ')
                : '${names.take(2).join(', ')} 외 ${names.length - 2}명';

        return Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 11.sp,
            fontWeight: FontWeight.w400,
          ),
        );
      }

      return FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchMemberDetails(state.chatRoom!.participants),
        builder: (ctx, snap) {
          if (!snap.hasData) return const SizedBox.shrink();
          final names =
              snap.data!.map((m) {
                final isMe = m['id'] == currentUserId;
                if (isMe) return '나';
                return resolveDisplayName(
                  m['id'] as String,
                  m['name'] as String? ?? '알 수 없음',
                );
              }).toList();

          final mi = names.indexOf('나');
          if (mi > 0) {
            names.removeAt(mi);
            names.insert(0, '나');
          }

          final subtitle =
              names.length <= 2
                  ? names.join(', ')
                  : '${names.take(2).join(', ')} 외 ${names.length - 2}명';

          return Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 11.sp,
              fontWeight: FontWeight.w400,
            ),
          );
        },
      );
    }

    return AppBar(
      backgroundColor: const Color(0xFFF2F2F2),
      elevation: 0,
      forceMaterialTransparency: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: GestureDetector(
        onTap: state.isGroup ? showMembersDialog : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            buildGroupTitleWidget(),
            if (state.isGroup && state.chatRoom != null) buildGroupSubtitle(),
          ],
        ),
      ),
    );
  }
}
