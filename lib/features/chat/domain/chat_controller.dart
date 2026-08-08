import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:ecommerece_app/core/models/product_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/chat_repository.dart';
import '../models/chat_room_model.dart';
import '../models/message_model.dart';

final chatRoomsProvider = StreamProvider<List<ChatRoomModel>>((ref) {
  final chatRepository = ref.watch(chatRepositoryProvider);
  return chatRepository.getChatRoomsStream();
});

final messagesProvider = StreamProvider.family<List<MessageModel>, String>((
  ref,
  chatRoomId,
) {
  final chatRepository = ref.watch(chatRepositoryProvider);
  return chatRepository.getMessagesStream(chatRoomId);
});

final chatControllerProvider = AsyncNotifierProvider<ChatController, void>(() {
  return ChatController();
});

class ChatController extends AsyncNotifier<void> {
  late final ChatRepository _chatRepository;

  @override
  FutureOr<void> build() {
    _chatRepository = ref.watch(chatRepositoryProvider);
  }

  Future<MyUser?> getOtherUserDoc(String otherId, String chatType) async {
    try {
      if (chatType == 'direct') {
        final doc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(otherId)
                .get();
        if (doc.exists) return MyUser.fromDocument(doc.data()!);
      } else if (chatType == 'seller' || chatType == 'admin') {
        final collectionName =
            chatType == 'seller' ? 'deliveryManagers' : 'users';
        final doc =
            await FirebaseFirestore.instance
                .collection(collectionName)
                .doc(otherId)
                .get();
        if (doc.exists) return MyUser.fromSellerDocument(doc.data()!);
      }
    } catch (e) {
      debugPrint('Error fetching other user doc: $e');
    }
    return null;
  }

  Future<String> createDirectChatRoom(String otherUserId, bool isBrand) {
    return _chatRepository.createDirectChatRoom(otherUserId, isBrand);
  }

  Future<List<String>> createDirectChatRoomWithSeller(String otherUserId) {
    return _chatRepository.createDirectChatRoomWithSeller(otherUserId);
  }

  Future<String> createDirectChatRoomWithAdmin() {
    return _chatRepository.createDirectChatRoomWithAdmin();
  }

  Future<String?> createGroupChatRoom({
    required String name,
    required List<String> participantIds,
    String? groupImage,
  }) {
    return _chatRepository.createGroupChatRoom(
      name: name,
      participantIds: participantIds,
      groupImage: groupImage,
    );
  }

  Future<void> sendMessage({
    required String chatRoomId,
    required String content,
    String? imageUrl,
    String? replyToMessageId,
    Map<String, dynamic>? postData,
    Product? productData,
  }) {
    return _chatRepository.sendMessage(
      chatRoomId: chatRoomId,
      content: content,
      imageUrl: imageUrl,
      replyToMessageId: replyToMessageId,
      postData: postData,
      productData: productData,
    );
  }

  Future<bool> toggleLoveReaction({
    required String messageId,
    required String chatRoomId,
  }) {
    return _chatRepository.toggleLoveReaction(
      messageId: messageId,
      chatRoomId: chatRoomId,
    );
  }

  Future<void> markSpecificMessagesAsRead(
    String chatRoomId,
    List<String> messageIds,
  ) {
    return _chatRepository.markSpecificMessagesAsRead(chatRoomId, messageIds);
  }

  Future<void> resetUnreadCount(String chatRoomId) {
    return _chatRepository.resetUnreadCount(chatRoomId);
  }

  Future<void> resetDeletedBy(String chatRoomId) {
    return _chatRepository.resetDeletedBy(chatRoomId);
  }

  Stream<List<ChatRoomModel>> getChatRoomsStream() {
    return _chatRepository.getChatRoomsStream();
  }

  Stream<List<MessageModel>> getMessagesStream(String chatRoomId) {
    return _chatRepository.getMessagesStream(chatRoomId);
  }

  Future<void> softDeleteChatForCurrentUser(String chatRoomId) {
    return _chatRepository.softDeleteChatForCurrentUser(chatRoomId);
  }

  Future<void> addParticipantToGroup(String chatRoomId, String userId) {
    return _chatRepository.addParticipantToGroup(chatRoomId, userId);
  }

  Future<void> removeParticipantFromGroup(String chatRoomId, String userId) {
    return _chatRepository.removeParticipantFromGroup(chatRoomId, userId);
  }

  Stream<Map<String, int>> getGroupChatsOrderStream() {
    return _chatRepository.getGroupChatsOrderStream();
  }

  Future<void> updateGroupChatImage(String chatRoomId, String imageUrl) {
    return _chatRepository.updateGroupChatImage(chatRoomId, imageUrl);
  }

  Future<void> updateGroupChatName(String chatRoomId, String newName) {
    return _chatRepository.updateGroupChatName(chatRoomId, newName);
  }

  /// Get a reply-to message document.
  Future<Map<String, dynamic>?> getReplyMessage(
    String chatRoomId,
    String messageId,
  ) => _chatRepository.getReplyMessage(chatRoomId, messageId);

  /// Get the other user's ID from a chat room.
  Future<String> getChatRoomOtherUserId(
    String chatRoomId,
    String currentUserId,
  ) => _chatRepository.getChatRoomOtherUserId(chatRoomId, currentUserId);

  /// Get a post document by ID.
  Future<Map<String, dynamic>?> getPostById(String postId) =>
      _chatRepository.getPostById(postId);

  /// Fetch a user's display name.
  Future<String> fetchUserName(String userId) =>
      _chatRepository.fetchUserName(userId);

  /// Update chat room consultation status.
  Future<void> updateChatRoomStatus(String chatRoomId, String status) =>
      _chatRepository.updateChatRoomStatus(chatRoomId, status);
}
