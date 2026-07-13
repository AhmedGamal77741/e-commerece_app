import 'package:ecommerece_app/features/chat/widgets/group_chat_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_room_model.dart';
import '../domain/chat_controller.dart';

class GroupChatsScreen extends ConsumerStatefulWidget {
  const GroupChatsScreen({super.key});

  @override
  ConsumerState<GroupChatsScreen> createState() => _GroupChatsScreenState();
}

class _GroupChatsScreenState extends ConsumerState<GroupChatsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final Stream<Map<String, int>> _groupChatsOrderStreamInstance;
  late final Stream<List<ChatRoomModel>> _chatRoomsStreamInstance;

  @override
  void initState() {
    super.initState();
    _groupChatsOrderStreamInstance = ref.read(chatControllerProvider.notifier).getGroupChatsOrderStream();
    _chatRoomsStreamInstance = ref.read(chatControllerProvider.notifier).getChatRoomsStream();
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<Map<String, int>>(
      stream: _groupChatsOrderStreamInstance,
      builder: (context, orderSnapshot) {
        final orderMap = orderSnapshot.data ?? {};

        return StreamBuilder<List<ChatRoomModel>>(
          stream: _chatRoomsStreamInstance,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox.shrink();
            }

            final groupChats =
                snapshot.data!.where((chat) => chat.type == 'group').toList();

            // Sort by order from edit screen
            groupChats.sort((a, b) {
              final aOrder = orderMap[a.id] ?? 999999;
              final bOrder = orderMap[b.id] ?? 999999;
              return aOrder.compareTo(bOrder);
            });

            if (groupChats.isEmpty) {
              return const Center(child: Text('그룹채팅 없음.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groupChats.length,
              itemBuilder: (context, index) {
                final chat = groupChats[index];
                return GroupChatTile(chat: chat);
              },
            );
          },
        );
      },
    );
  }
}
