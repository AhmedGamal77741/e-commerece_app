import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:ecommerece_app/features/chat/domain/friends_controller.dart';
import 'package:ecommerece_app/core/providers/firebase_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_room_model.dart';
import '../domain/chat_controller.dart';
import '../widgets/direct_chat_tile.dart';

class DirectChatsScreen extends ConsumerStatefulWidget {
  const DirectChatsScreen({super.key});

  @override
  ConsumerState<DirectChatsScreen> createState() => _DirectChatsScreenState();
}

class _DirectChatsScreenState extends ConsumerState<DirectChatsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String get currentUserId => ref.watch(currentUserIdProvider);

  final Map<String, MyUser?> _usersCache = {};
  final Set<String> _fetchingIds = {};

  // ─── Hidden IDs stream ────────────────────────────────────────────────────
  Stream<Set<String>> _getHiddenIdsStream() {
    return ref.read(friendsControllerProvider.notifier).getHiddenIdsStream();
  }

  // ─── Alias map stream ─────────────────────────────────────────────────────
  Stream<Map<String, String>> _getAliasesStream() {
    return ref.read(friendsControllerProvider.notifier).getAliasesStream();
  }

  // ─── Resolve other participant ────────────────────────────────────────────
  Future<void> getOtherUser(ChatRoomModel chat) async {
    final otherId = chat.participants.firstWhere(
      (id) => id != currentUserId,
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
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      _fetchingIds.remove(otherId);
    }
  }

  String _getOtherUserId(ChatRoomModel chat) {
    return chat.participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<Set<String>>(
      stream: _getHiddenIdsStream(),
      builder: (context, hiddenSnapshot) {
        final hiddenIds = hiddenSnapshot.data ?? {};

        return StreamBuilder<Map<String, String>>(
          stream: _getAliasesStream(),
          builder: (context, aliasSnapshot) {
            final aliases = aliasSnapshot.data ?? {};

            return StreamBuilder<List<ChatRoomModel>>(
              stream:
                  ref
                      .read(chatControllerProvider.notifier)
                      .getChatRoomsStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final directChats =
                    snapshot.data!
                        .where(
                          (chat) =>
                              (chat.type == 'direct' ||
                                  chat.type == 'seller' ||
                                  chat.type == 'admin' ||
                                  chat.type == '') &&
                              !chat.deletedBy.contains(currentUserId) &&
                              chat.lastMessage != null &&
                              chat.lastMessage!.isNotEmpty,
                        )
                        .toList();

                if (directChats.isEmpty) {
                  return const Center(child: Text('직접 채팅 없음.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: directChats.length,
                  itemBuilder: (context, index) {
                    final chat = directChats[index];

                    final otherId = _getOtherUserId(chat);
                    if (otherId.isNotEmpty && hiddenIds.contains(otherId)) {
                      return const SizedBox.shrink();
                    }

                    if (!_usersCache.containsKey(otherId)) {
                      getOtherUser(chat);
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey[300],
                          radius: 25,
                          child: Icon(Icons.person, color: Colors.black),
                        ),
                        title: Text('Loading...'),
                      );
                    }

                    final friend = _usersCache[otherId];
                    if (friend == null) {
                      return DirectChatTile(
                        chat: chat,
                        displayName: '삭제된 사용자',
                        realName: null,
                        avatarUrl: null,
                        userId: '',
                        isDeleted: true,
                      );
                    }

                    final String displayName =
                        aliases[friend.userId] ?? friend.name;
                    final bool hasAlias = displayName != friend.name;

                    return DirectChatTile(
                      chat: chat,
                      displayName: displayName,
                      realName: hasAlias ? friend.name : null,
                      avatarUrl: friend.url.isNotEmpty ? friend.url : null,
                      userId: friend.userId,
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
