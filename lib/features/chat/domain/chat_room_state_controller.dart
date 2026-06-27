import 'dart:async';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/features/chat/domain/chat_controller.dart';
import 'package:ecommerece_app/features/chat/models/chat_room_model.dart';
import 'package:ecommerece_app/features/chat/models/message_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:ecommerece_app/core/helpers/image_picker_helper.dart';

class ChatRoomState {
  final XFile? pickedImage;
  final Uint8List? pickedImageBytes;
  final bool isBlocked;
  final bool blocked;
  final bool loadingBlockState;
  final MessageModel? replyToMessage;
  final List<MessageModel> messages;
  final bool messagesLoaded;
  final ChatRoomModel? chatRoom;
  final bool isGroup;
  final bool roomDeleted;
  final Map<String, String> aliases;
  final String otherUserId;

  ChatRoomState({
    this.pickedImage,
    this.pickedImageBytes,
    this.isBlocked = false,
    this.blocked = false,
    this.loadingBlockState = true,
    this.replyToMessage,
    this.messages = const [],
    this.messagesLoaded = false,
    this.chatRoom,
    this.isGroup = false,
    this.roomDeleted = false,
    this.aliases = const {},
    this.otherUserId = '',
  });

  ChatRoomState copyWith({
    XFile? pickedImage,
    bool clearPickedImage = false,
    Uint8List? pickedImageBytes,
    bool clearPickedImageBytes = false,
    bool? isBlocked,
    bool? blocked,
    bool? loadingBlockState,
    MessageModel? replyToMessage,
    bool clearReplyToMessage = false,
    List<MessageModel>? messages,
    bool? messagesLoaded,
    ChatRoomModel? chatRoom,
    bool? isGroup,
    bool? roomDeleted,
    Map<String, String>? aliases,
    String? otherUserId,
  }) {
    return ChatRoomState(
      pickedImage: clearPickedImage ? null : (pickedImage ?? this.pickedImage),
      pickedImageBytes: clearPickedImageBytes ? null : (pickedImageBytes ?? this.pickedImageBytes),
      isBlocked: isBlocked ?? this.isBlocked,
      blocked: blocked ?? this.blocked,
      loadingBlockState: loadingBlockState ?? this.loadingBlockState,
      replyToMessage: clearReplyToMessage ? null : (replyToMessage ?? this.replyToMessage),
      messages: messages ?? this.messages,
      messagesLoaded: messagesLoaded ?? this.messagesLoaded,
      chatRoom: chatRoom ?? this.chatRoom,
      isGroup: isGroup ?? this.isGroup,
      roomDeleted: roomDeleted ?? this.roomDeleted,
      aliases: aliases ?? this.aliases,
      otherUserId: otherUserId ?? this.otherUserId,
    );
  }
}

class ChatRoomStateController extends StateNotifier<ChatRoomState> {
  late TextEditingController messageController;
  late ScrollController scrollController;
  late String currentUserId;
  final String chatRoomId;
  final Ref ref;

  StreamSubscription<List<MessageModel>>? _messageSubscription;
  StreamSubscription<DocumentSnapshot>? _roomSubscription;
  StreamSubscription<DocumentSnapshot>? _currentUserSubscription;
  StreamSubscription<DocumentSnapshot>? _otherUserSubscription;

  ChatRoomStateController(this.ref, this.chatRoomId) : super(ChatRoomState()) {
    messageController = TextEditingController();
    scrollController = ScrollController();
    currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    _resetUnreadCount();
    _loadChatRoom();
    _messageSubscription = ref.read(chatControllerProvider.notifier).getMessagesStream(chatRoomId)
        .listen((messages) {
          state = state.copyWith(messages: messages, messagesLoaded: true);
          final unreadIds = messages
              .where((m) => m.senderId != currentUserId && !m.readBy.contains(currentUserId))
              .map((m) => m.id)
              .toList();
          if (unreadIds.isNotEmpty) {
            ref.read(chatControllerProvider.notifier).markSpecificMessagesAsRead(chatRoomId, unreadIds);
          }
        });
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    _messageSubscription?.cancel();
    _roomSubscription?.cancel();
    _currentUserSubscription?.cancel();
    _otherUserSubscription?.cancel();
    super.dispose();
  }

  void _resetUnreadCount() {
    ref.read(chatControllerProvider.notifier).resetUnreadCount(chatRoomId);
  }

  void _loadChatRoom() {
    try {
      _roomSubscription = FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(chatRoomId)
          .snapshots()
          .listen((doc) async {
        if (!doc.exists) {
          state = state.copyWith(roomDeleted: true, loadingBlockState: false);
          return;
        }

        final room = ChatRoomModel.fromMap(doc.data()!);

        if (room.type == 'group') {
          await _loadAliases(room.participants);
          state = state.copyWith(
            chatRoom: room,
            isGroup: true,
            loadingBlockState: false,
          );
        } else {
          final otherId = room.participants.firstWhere(
            (id) => id != currentUserId,
            orElse: () => '',
          );
          state = state.copyWith(otherUserId: otherId);
          await _loadAliases(room.participants);
          
          _currentUserSubscription?.cancel();
          _currentUserSubscription = FirebaseFirestore.instance
              .collection('users')
              .doc(currentUserId)
              .snapshots()
              .listen((doc) {
            state = state.copyWith(
              blocked: List<String>.from(doc.data()?['blocked'] ?? []).contains(otherId),
              loadingBlockState: false,
            );
          });

          _otherUserSubscription?.cancel();
          _otherUserSubscription = FirebaseFirestore.instance
              .collection('users')
              .doc(otherId)
              .snapshots()
              .listen((doc) {
            state = state.copyWith(
              isBlocked: List<String>.from(doc.data()?['blocked'] ?? []).contains(currentUserId),
              loadingBlockState: false,
            );
          });

          state = state.copyWith(
            chatRoom: room,
            isGroup: false,
          );
        }
      });
    } catch (e) {
      debugPrint('Error loading chat room: $e');
      state = state.copyWith(loadingBlockState: false);
    }
  }

  Future<void> _loadAliases(List<String> userIds) async {
    if (currentUserId.isEmpty) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('aliases')
          .get();
      final map = <String, String>{};
      for (final d in snap.docs) {
        final alias = d.data()['alias'] as String?;
        if (alias != null && alias.isNotEmpty && userIds.contains(d.id)) {
          map[d.id] = alias;
        }
      }
      state = state.copyWith(aliases: map);
    } catch (e) {
      debugPrint('Error loading aliases: $e');
    }
  }

  Future<void> pickImage() async {
    final picked = await ImagePickerHelper.pickImage();
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      state = state.copyWith(pickedImage: picked, pickedImageBytes: bytes);
    }
  }

  void clearPickedImage() {
    state = state.copyWith(clearPickedImage: true, clearPickedImageBytes: true);
  }

  Future<void> unblockUser(String otherUserId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .update({
          'blocked': FieldValue.arrayRemove([otherUserId]),
        });
    state = state.copyWith(blocked: false);
  }

  void setReplyToMessage(MessageModel? message) {
    state = state.copyWith(
      replyToMessage: message,
      clearReplyToMessage: message == null,
    );
  }

  Future<void> sendImageMessage() async {
    if (state.pickedImageBytes == null) return;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_$currentUserId.jpg';
    final storageRef = FirebaseStorage.instance.ref().child('chat_images/$fileName');

    final content = messageController.text.trim();
    final imageBytes = state.pickedImageBytes!;
    final replyId = state.replyToMessage?.id;

    messageController.clear();
    state = state.copyWith(
      clearPickedImage: true,
      clearPickedImageBytes: true,
      clearReplyToMessage: true,
    );

    try {
      final UploadTask task = storageRef.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final TaskSnapshot snapshot = await task;
      final url = await snapshot.ref.getDownloadURL();
      await ref.read(chatControllerProvider.notifier).sendMessage(
        chatRoomId: chatRoomId,
        content: content,
        imageUrl: url,
        replyToMessageId: replyId,
      );
      await ref.read(chatControllerProvider.notifier).resetDeletedBy(chatRoomId);
    } catch (e) {
      debugPrint('Error sending image message: $e');
    }
  }

  Future<void> sendMessage() async {
    final content = messageController.text.trim();
    if (content.isEmpty) return;

    messageController.clear();
    final replyId = state.replyToMessage?.id;
    state = state.copyWith(clearReplyToMessage: true);

    try {
      await ref.read(chatControllerProvider.notifier).sendMessage(
        chatRoomId: chatRoomId,
        content: content,
        replyToMessageId: replyId,
      );
      await ref.read(chatControllerProvider.notifier).resetDeletedBy(chatRoomId);
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }
}

final chatRoomStateControllerProvider = StateNotifierProvider.autoDispose.family<ChatRoomStateController, ChatRoomState, String>((ref, id) {
  return ChatRoomStateController(ref, id);
});
