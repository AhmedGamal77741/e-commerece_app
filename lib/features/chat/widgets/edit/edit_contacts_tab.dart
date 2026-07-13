import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:ecommerece_app/features/chat/domain/edit_screen_controller.dart';
import 'package:ecommerece_app/features/chat/services/favorites_service.dart';
import 'package:ecommerece_app/features/chat/domain/friends_controller.dart';
import 'package:ecommerece_app/features/home/domain/feed_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EditContactsTab extends ConsumerStatefulWidget {
  const EditContactsTab({super.key});

  @override
  ConsumerState<EditContactsTab> createState() => _EditContactsTabState();
}

class _EditContactsTabState extends ConsumerState<EditContactsTab> {
  final FavoritesService _favoritesService = FavoritesService();

  Stream<Set<String>> _hiddenIdsStream(String uid) {
    return ref.read(friendsControllerProvider.notifier).getHiddenIdsStreamForUser(uid);
  }

  Stream<List<String>> _blockedIdsStream(String uid) {
    return ref.read(friendsControllerProvider.notifier).getBlockedIdsStream(uid);
  }

  Stream<Map<String, int>> _favoriteOrderStream(String uid) {
    return ref.read(friendsControllerProvider.notifier).getFavoriteOrderStream(uid);
  }

  Future<void> _removeFavorite(String uid, String userId) async {
    await ref.read(friendsControllerProvider.notifier).removeFavoriteAndOrder(uid, userId);
  }

  Future<void> _unhide(String uid, String userId) async {
    await ref.read(friendsControllerProvider.notifier).unhideUserFriend(uid, userId);
  }

  Future<void> _hide(String uid, MyUser friend) async {
    await ref.read(friendsControllerProvider.notifier).hideUserFriend(uid, friend.userId);
  }

  Future<void> _unblock(String blockedUserId) async {
    await ref.read(feedControllerProvider.notifier).unblockUser(userIdToUnblock: blockedUserId);
  }

  Future<void> _reorderFavorites(String uid, List<MyUser> newOrder) async {
    final orderMap = <String, int>{};
    for (int i = 0; i < newOrder.length; i++) {
      orderMap[newOrder[i].userId] = i;
    }
    await ref.read(friendsControllerProvider.notifier).reorderFavorites(uid, orderMap);
  }

  late final Stream<List<String>> _favoriteIdsStreamInstance;
  late final Stream<Map<String, int>> _favoriteOrderStreamInstance;
  late final Stream<Set<String>> _hiddenIdsStreamInstance;
  late final Stream<List<String>> _blockedIdsStreamInstance;
  late final Stream<List<MyUser>> _friendsStreamInstance;

  @override
  void initState() {
    super.initState();
    final uid = ref.read(editScreenControllerProvider(0).notifier).uid;
    _favoriteIdsStreamInstance = _favoritesService.getFavoriteIdsStream();
    _favoriteOrderStreamInstance = _favoriteOrderStream(uid);
    _hiddenIdsStreamInstance = _hiddenIdsStream(uid);
    _blockedIdsStreamInstance = _blockedIdsStream(uid);
    _friendsStreamInstance = ref.read(friendsControllerProvider.notifier).getFriendsStream();
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 16.w, top: 20.h, bottom: 8.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12.sp,
          color: Colors.grey[500],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _friendRow({
    required MyUser user,
    required Widget trailing,
    Map<String, String> aliases = const {},
  }) {
    final displayName = aliases[user.userId] ?? user.name;
    final hasAlias =
        aliases.containsKey(user.userId) && aliases[user.userId]!.isNotEmpty;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22.r,
            backgroundImage:
                user.url.isNotEmpty ? NetworkImage(user.url) : null,
            backgroundColor: Colors.grey[200],
            child:
                user.url.isEmpty
                    ? Icon(Icons.person, size: 20.sp, color: Colors.grey)
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
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
                if (hasAlias)
                  Text(
                    user.name,
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey[400]),
                  ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _pillButton(String label, VoidCallback onTap, {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: color ?? Colors.black87),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editScreenControllerProvider(0));
    final q = state.query;
    final aliases = state.aliases;
    final uid = ref.read(editScreenControllerProvider(0).notifier).uid;

    return StreamBuilder<List<String>>(
      stream: _favoriteIdsStreamInstance,
      builder: (ctx, favSnap) {
        final favIds = favSnap.data ?? [];

        return StreamBuilder<Map<String, int>>(
          stream: _favoriteOrderStreamInstance,
          builder: (ctx, orderSnap) {
            final orderMap = orderSnap.data ?? {};

            return StreamBuilder<Set<String>>(
              stream: _hiddenIdsStreamInstance,
              builder: (ctx, hiddenSnap) {
                final hiddenIds = hiddenSnap.data ?? {};

                return StreamBuilder<List<String>>(
                  stream: _blockedIdsStreamInstance,
                  builder: (ctx, blockedSnap) {
                    final blockedIds = blockedSnap.data ?? [];

                    return StreamBuilder<List<MyUser>>(
                      stream: _friendsStreamInstance,
                      builder: (ctx, friendsSnap) {
                        if (!friendsSnap.hasData) {
                          return const SizedBox.shrink();
                        }

                        final allFriends =
                            friendsSnap.data!
                                .where((u) => u.type == 'user')
                                .toList();

                        final filtered =
                            q.isEmpty
                                ? allFriends
                                : allFriends.where((u) {
                                  final alias =
                                      aliases[u.userId]?.toLowerCase() ?? '';
                                  return u.name.toLowerCase().contains(q) ||
                                      alias.contains(q);
                                }).toList();

                        final favorites =
                            filtered
                                .where(
                                  (u) =>
                                      favIds.contains(u.userId) &&
                                      !hiddenIds.contains(u.userId),
                                )
                                .toList()
                              ..sort((a, b) {
                                final aO = orderMap[a.userId] ?? 999999;
                                final bO = orderMap[b.userId] ?? 999999;
                                return aO.compareTo(bO);
                              });

                        final friends =
                            filtered
                                .where(
                                  (u) =>
                                      !favIds.contains(u.userId) &&
                                      !hiddenIds.contains(u.userId),
                                )
                                .toList();

                        final hiddenUsers =
                            filtered
                                .where((u) => hiddenIds.contains(u.userId))
                                .toList();

                        return ListView(
                              children: [
                                if (favorites.isNotEmpty) ...[
                                  _sectionHeader('즐겨찾기'),
                                  ReorderableListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    buildDefaultDragHandles: false,
                                    itemCount: favorites.length,
                                    proxyDecorator:
                                        (child, index, animation) =>
                                            Material(
                                              color: ColorsManager.primary,
                                              child: child,
                                            ),
                                    onReorder: (oldIdx, newIdx) {
                                      final reordered = List<MyUser>.from(favorites);
                                      if (newIdx > oldIdx) newIdx--;
                                      final item = reordered.removeAt(oldIdx);
                                      reordered.insert(newIdx, item);
                                      _reorderFavorites(uid, reordered);
                                    },
                                    itemBuilder: (ctx, index) {
                                      final u = favorites[index];
                                      final displayName =
                                          aliases[u.userId] ?? u.name;
                                      final hasAlias =
                                          aliases.containsKey(u.userId) &&
                                          aliases[u.userId]!.isNotEmpty;

                                      return Container(
                                        key: ValueKey(u.userId),
                                        color: ColorsManager.primary,
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16.w,
                                            vertical: 8.h,
                                          ),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 22.r,
                                                backgroundImage:
                                                    u.url.isNotEmpty
                                                        ? NetworkImage(u.url)
                                                        : null,
                                                backgroundColor:
                                                    Colors.grey[200],
                                                child:
                                                    u.url.isEmpty
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
                                                        fontSize: 15.sp,
                                                        fontWeight: FontWeight.w400,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                    if (hasAlias)
                                                      Text(
                                                        u.name,
                                                        style: TextStyle(
                                                          fontSize: 11.sp,
                                                          color: Colors.grey[400],
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              _pillButton(
                                                '해제',
                                                () => _removeFavorite(uid, u.userId),
                                              ),
                                              SizedBox(width: 8.w),
                                              ReorderableDragStartListener(
                                                index: index,
                                                child: Icon(
                                                  Icons.drag_handle,
                                                  color: Colors.grey[400],
                                                  size: 20.sp,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                                if (friends.isNotEmpty) ...[
                                  _sectionHeader('친구'),
                                  ...friends.map(
                                    (u) => _friendRow(
                                      user: u,
                                      aliases: aliases,
                                      trailing: _pillButton(
                                        '거리두기',
                                        () => _hide(uid, u),
                                      ),
                                    ),
                                  ),
                                ],
                                if (hiddenUsers.isNotEmpty) ...[
                                  _sectionHeader('거리두기한 친구'),
                                  ...hiddenUsers.map(
                                    (u) => _friendRow(
                                      user: u,
                                      aliases: aliases,
                                      trailing: _pillButton(
                                        '해제',
                                        () => _unhide(uid, u.userId),
                                      ),
                                    ),
                                  ),
                                ],
                                if (blockedIds.isNotEmpty) ...[
                                  _sectionHeader('차단된 친구'),
                                  ...blockedIds.map(
                                    (id) => BlockedUserRow(
                                      userId: id,
                                      onUnblock: () => _unblock(id),
                                      buildRow: (user, trailing) => _friendRow(user: user, trailing: trailing),
                                    ),
                                  ),
                                ],
                                SizedBox(height: 40.h),
                              ],
                            );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

}

class BlockedUserRow extends ConsumerWidget {
  final String userId;
  final VoidCallback onUnblock;
  final Widget Function(MyUser user, Widget trailing) buildRow;

  const BlockedUserRow({
    super.key,
    required this.userId,
    required this.onUnblock,
    required this.buildRow,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docAsync = ref.watch(userProfileDocProvider(userId));
    return docAsync.when(
      data: (doc) {
        if (doc == null || !doc.exists) return const SizedBox.shrink();
        final user = MyUser.fromDocument(doc.data() as Map<String, dynamic>);
        return buildRow(
          user,
          GestureDetector(
            onTap: onUnblock,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                '해제',
                style: TextStyle(fontSize: 12.sp, color: Colors.red[400]),
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
