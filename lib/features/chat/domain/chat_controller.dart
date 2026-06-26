import 'package:ecommerece_app/core/models/product_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/chat_repository.dart';
import '../models/chat_room_model.dart';
import '../models/message_model.dart';

final chatRoomsProvider = StreamProvider<List<ChatRoomModel>>((ref) {
  final chatRepository = ref.watch(chatRepositoryProvider);
  return chatRepository.getChatRoomsStream();
});

final messagesProvider = StreamProvider.family<List<MessageModel>, String>((ref, chatRoomId) {
  final chatRepository = ref.watch(chatRepositoryProvider);
  return chatRepository.getMessagesStream(chatRoomId);
});

final chatControllerProvider = Provider<ChatController>((ref) {
  return ChatController(chatRepository: ref.watch(chatRepositoryProvider));
});

class ChatController {
  final ChatRepository _chatRepository;

  ChatController({required ChatRepository chatRepository})
      : _chatRepository = chatRepository;

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
    bool isStory = false,
    String? storyId = '',
    Map<String, dynamic>? postData,
    Product? productData,
  }) {
    return _chatRepository.sendMessage(
      chatRoomId: chatRoomId,
      content: content,
      imageUrl: imageUrl,
      replyToMessageId: replyToMessageId,
      isStory: isStory,
      storyId: storyId,
      postData: postData,
      productData: productData,
    );
  }

  Future<bool> toggleLoveReaction({required String messageId, required String chatRoomId}) {
    return _chatRepository.toggleLoveReaction(messageId: messageId, chatRoomId: chatRoomId);
  }

  Future<void> markSpecificMessagesAsRead(String chatRoomId, List<String> messageIds) {
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
}
