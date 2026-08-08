import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:ecommerece_app/core/models/product_model.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../models/chat_room_model.dart';
import '../models/message_model.dart';
import 'friends_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(
    firestore: ref.watch(firestoreProvider),
    auth: ref.watch(authProvider),
    friendsRepository: ref.watch(friendsRepositoryProvider),
  );
});

class ChatRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FriendsRepository _friendsRepository;

  ChatRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required FriendsRepository friendsRepository,
  })  : _firestore = firestore,
        _auth = auth,
        _friendsRepository = friendsRepository;

  String get currentUserId => _auth.currentUser?.uid ?? '';

  Future<String> createDirectChatRoom(String otherUserId, bool isBrand) async {
    const String supportUserId = 'JuxEfED9YSc2XyHRFgkPcNCFUSJ3';
    if (otherUserId != supportUserId) {
      final areFriends = await _friendsRepository.areFriends(otherUserId);
      if (!areFriends && !isBrand) {
        throw Exception('You can only chat with friends');
      }
    }

    final participants = [currentUserId, otherUserId]..sort();
    final chatRoomId = participants.join('_');

    final chatRoomRef = _firestore.collection('chatRooms').doc(chatRoomId);
    final chatRoomDoc = await chatRoomRef.get();

    if (!chatRoomDoc.exists) {
      final otherUserDoc =
          await _firestore.collection('users').doc(otherUserId).get();
      if (!otherUserDoc.exists) {
        throw Exception('Other user not found');
      }

      final otherUser = MyUser.fromDocument(otherUserDoc.data()!);
      final now = DateTime.now();

      final chatRoom = ChatRoomModel(
        id: chatRoomId,
        name: otherUser.name,
        type: 'direct',
        participants: participants,
        lastMessageTime: now,
        createdAt: now,
        unreadCount: {currentUserId: 0, otherUserId: 0},
      );

      final batch = _firestore.batch();
      batch.set(chatRoomRef, chatRoom.toMap());
      batch.update(_firestore.collection('users').doc(currentUserId), {
        'chatRooms': FieldValue.arrayUnion([chatRoomId]),
      });
      batch.update(_firestore.collection('users').doc(otherUserId), {
        'chatRooms': FieldValue.arrayUnion([chatRoomId]),
      });
      await batch.commit();
    }

    return chatRoomId;
  }

  Future<List<String>> createDirectChatRoomWithSeller(String otherUserId) async {
    final participants = [currentUserId, otherUserId]..sort();
    final chatRoomId = participants.join('_');

    final chatRoomRef = _firestore.collection('chatRooms').doc(chatRoomId);
    final chatRoomDoc = await chatRoomRef.get();
    String otherUserName = "";

    if (!chatRoomDoc.exists) {
      final otherUserDoc = await _firestore.collection('deliveryManagers').doc(otherUserId).get();
      if (!otherUserDoc.exists) {
        throw Exception('Other user not found');
      }

      final otherUser = otherUserDoc.data()!;
      final now = DateTime.now();
      otherUserName = otherUser['brandName'] ?? otherUser['name'] ?? '';

      final chatRoom = ChatRoomModel(
        id: chatRoomId,
        name: otherUserName,
        type: 'seller',
        participants: participants,
        lastMessageTime: now,
        createdAt: now,
        unreadCount: {currentUserId: 0, otherUserId: 0},
      );

      final batch = _firestore.batch();
      batch.set(chatRoomRef, chatRoom.toMap());
      batch.update(_firestore.collection('users').doc(currentUserId), {
        'chatRooms': FieldValue.arrayUnion([chatRoomId]),
      });
      batch.update(_firestore.collection('deliveryManagers').doc(otherUserId), {
        'chatRooms': FieldValue.arrayUnion([chatRoomId]),
      });
      await batch.commit();
    } else {
      otherUserName = chatRoomDoc.data()!['name'];
    }

    return [chatRoomId, otherUserName];
  }

  Future<String> createDirectChatRoomWithAdmin() async {
    final participants = [currentUserId, "Admin"]..sort();
    final chatRoomId = participants.join('_');

    final chatRoomRef = _firestore.collection('chatRooms').doc(chatRoomId);
    final chatRoomDoc = await chatRoomRef.get();

    if (!chatRoomDoc.exists) {
      final now = DateTime.now();
      final chatRoom = ChatRoomModel(
        id: chatRoomId,
        name: "Admin",
        type: 'admin',
        participants: participants,
        lastMessageTime: now,
        createdAt: now,
        unreadCount: {currentUserId: 0, "Admin": 0},
      );

      final batch = _firestore.batch();
      batch.set(chatRoomRef, chatRoom.toMap());
      batch.update(_firestore.collection('users').doc(currentUserId), {
        'chatRooms': FieldValue.arrayUnion([chatRoomId]),
      });
      batch.update(_firestore.collection('users').doc("Admin"), {
        'chatRooms': FieldValue.arrayUnion([chatRoomId]),
      });
      await batch.commit();
    }

    return chatRoomId;
  }

  Future<bool> toggleLoveReaction({required String messageId, required String chatRoomId}) async {
    try {
      final messageRef = _firestore.collection('messages').doc(messageId);
      final messageDoc = await messageRef.get();

      if (!messageDoc.exists) return false;

      final message = MessageModel.fromMap(messageDoc.data()!);
      final isLoved = message.lovedBy.contains(currentUserId);

      if (isLoved) {
        await messageRef.update({
          'lovedBy': FieldValue.arrayRemove([currentUserId]),
        });
      } else {
        await messageRef.update({
          'lovedBy': FieldValue.arrayUnion([currentUserId]),
        });
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String?> createGroupChatRoom({
    required String name,
    required List<String> participantIds,
    String? groupImage,
  }) async {
    for (String participantId in participantIds) {
      final areFriends = await _friendsRepository.areFriends(participantId);
      if (!areFriends) {
        throw Exception('You can only add friends to group chats');
      }
    }

    final chatRoomRef = _firestore.collection('chatRooms').doc();
    final chatRoomId = chatRoomRef.id;

    final participants = [currentUserId, ...participantIds];
    final unreadCount = <String, int>{};
    for (String userId in participants) {
      unreadCount[userId] = 0;
    }

    final chatRoom = ChatRoomModel(
      id: chatRoomId,
      name: name,
      type: 'group',
      participants: participants,
      lastMessageTime: DateTime.now(),
      createdAt: DateTime.now(),
      createdBy: currentUserId,
      groupImage: groupImage,
      unreadCount: unreadCount,
    );

    await chatRoomRef.set(chatRoom.toMap());

    for (String userId in participants) {
      await _updateUserChatRooms(userId, chatRoomId);
    }

    return chatRoomId;
  }

  Future<Map<String, dynamic>?> _fetchProductFromUrl(String text) async {
    try {
      final match =
          RegExp(r'(?:/product/|productId=)([a-zA-Z0-9_-]+)').firstMatch(text);
      if (match != null) {
        final productId = match.group(1);
        if (productId != null && productId.isNotEmpty) {
          final doc =
              await _firestore.collection('products').doc(productId).get();
          if (doc.exists && doc.data() != null) {
            final data = Map<String, dynamic>.from(doc.data() as Map);
            data['product_id'] = doc.id;
            data['id'] = doc.id;
            return data;
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching product from text: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> _fetchPostFromUrl(String text) async {
    try {
      final match =
          RegExp(r'(?:/post/|postId=)([a-zA-Z0-9_-]+)').firstMatch(text);
      if (match != null) {
        final postId = match.group(1);
        if (postId != null && postId.isNotEmpty) {
          final doc = await _firestore.collection('posts').doc(postId).get();
          if (doc.exists && doc.data() != null) {
            final data = Map<String, dynamic>.from(doc.data() as Map);
            data['id'] = doc.id;
            data['postId'] = doc.id;
            return data;
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching post from text: $e');
    }
    return null;
  }

  Future<void> sendMessage({
    required String chatRoomId,
    required String content,
    String? imageUrl,
    String? replyToMessageId,
    Map<String, dynamic>? postData,
    Product? productData,
  }) async {
    final chatRoomDoc = await _firestore.collection('chatRooms').doc(chatRoomId).get();
    if (!chatRoomDoc.exists) {
      throw Exception('Chat room no longer exists or you are blocked.');
    }
    
    final chatRoom = ChatRoomModel.fromMap(chatRoomDoc.data()!);
    if (!chatRoom.participants.contains(currentUserId)) {
      throw Exception('You are no longer a participant in this chat.');
    }

    if (chatRoom.type == 'direct') {
      final otherUserId = chatRoom.participants.firstWhere((id) => id != currentUserId, orElse: () => '');
      if (otherUserId.isNotEmpty) {
        final receiverDoc = await _firestore.collection('users').doc(otherUserId).get();
        if (receiverDoc.exists) {
          final receiverBlocked = List<String>.from(receiverDoc.data()?['blocked'] ?? []);
          if (receiverBlocked.contains(currentUserId)) {
            throw Exception('You are blocked by this user.');
          }
        }
        
        final areFriends = await _friendsRepository.areFriends(otherUserId);
        if (!areFriends) {
          throw Exception('You can only chat with friends.');
        }
      }
    }

    if (postData == null && productData == null && content.isNotEmpty) {
      final pData = await _fetchProductFromUrl(content);
      if (pData != null) {
        productData = Product.fromMap(pData);
      } else {
        postData = await _fetchPostFromUrl(content);
      }
    }

    final messageRef = _firestore.collection('messages').doc();
    final messageId = messageRef.id;

    final userDoc = await _firestore.collection('users').doc(currentUserId).get();
    final user = MyUser.fromDocument(userDoc.data()!);

    final message = MessageModel(
      id: messageId,
      chatRoomId: chatRoomId,
      senderId: currentUserId,
      senderName: user.name,
      content: content,
      imageUrl: imageUrl,
      timestamp: DateTime.now(),
      readBy: [currentUserId],
      replyToMessageId: replyToMessageId,
      postData: postData,
      productData: productData,
    );

    final subRef = _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .doc(messageId);

    final batch = _firestore.batch();
    batch.set(messageRef, message.toMap());
    batch.set(subRef, message.toMap());
    await batch.commit();

    final String lastMessageText =
        (content.isEmpty && imageUrl != null && imageUrl.isNotEmpty)
            ? '[사진]'
            : content;

    final Map<String, dynamic> roomUpdates = {
      'lastMessage': lastMessageText,
      'lastMessageTime': message.timestamp.millisecondsSinceEpoch,
      'lastMessageSenderId': currentUserId,
      'lastMessageSenderName': user.name,
    };

    final currentStatus = chatRoomDoc.data()?['status'] as String?;
    if (currentStatus != null && currentStatus.toLowerCase() == 'completed') {
      roomUpdates['status'] = 'In Progress';
    }

    await _firestore.collection('chatRooms').doc(chatRoomId).update(roomUpdates);

    final updatedUnreadCount = Map<String, int>.from(chatRoom.unreadCount);
    for (String participantId in chatRoom.participants) {
      if (participantId != currentUserId) {
        updatedUnreadCount[participantId] =
            (updatedUnreadCount[participantId] ?? 0) + 1;
      }
    }

    await _firestore.collection('chatRooms').doc(chatRoomId).update({
      'unreadCount': updatedUnreadCount,
    });
  }

  Future<void> updateChatRoomStatus(String chatRoomId, String status) async {
    await _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .update({'status': status});
  }

  Future<void> resetDeletedBy(String chatRoomId) async {
    await _firestore.collection('chatRooms').doc(chatRoomId).update({
      'deletedBy': [],
    });
  }

  Future<void> softDeleteChatForCurrentUser(String chatRoomId) async {
    final batch = _firestore.batch();

    final chatRoomRef = _firestore.collection('chatRooms').doc(chatRoomId);
    batch.update(chatRoomRef, {
      'deletedBy': FieldValue.arrayUnion([currentUserId]),
    });

    final messagesQuery = await _firestore
        .collection('messages')
        .where('chatRoomId', isEqualTo: chatRoomId)
        .get();

    for (final doc in messagesQuery.docs) {
      batch.update(doc.reference, {
        'deletedBy': FieldValue.arrayUnion([currentUserId]),
      });
    }

    await batch.commit();
  }

  Future<void> resetUnreadCount(String chatRoomId) async {
    final roomRef = _firestore.collection('chatRooms').doc(chatRoomId);
    final roomDoc = await roomRef.get();
    if (roomDoc.exists) {
      final data = roomDoc.data();
      final unreadCount = Map<String, dynamic>.from(data?['unreadCount'] ?? {});
      final myUnread = unreadCount[currentUserId] ?? 0;
      if (myUnread > 0) {
        await roomRef.update({
          'unreadCount.$currentUserId': 0,
        });
      }
    }
  }

  Future<void> markSpecificMessagesAsRead(String chatRoomId, List<String> messageIds) async {
    if (messageIds.isEmpty) return;

    final batch = _firestore.batch();
    for (final id in messageIds) {
      final msgRef = _firestore.collection('messages').doc(id);
      final subRef = _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(id);

      batch.set(msgRef, {
        'readBy': FieldValue.arrayUnion([currentUserId]),
      }, SetOptions(merge: true));
      batch.set(subRef, {
        'readBy': FieldValue.arrayUnion([currentUserId]),
      }, SetOptions(merge: true));
    }

    try {
      await batch.commit();
      await resetUnreadCount(chatRoomId);
    } catch (e) {
      // ignore
    }
  }

  Stream<List<ChatRoomModel>> getChatRoomsStream() {
    return _firestore
        .collection('chatRooms')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
      final rooms = snapshot.docs
          .map((doc) => ChatRoomModel.fromMap(doc.data()))
          .toList();
      rooms.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      return rooms;
    });
  }

  Stream<List<MessageModel>> getMessagesStream(String chatRoomId) {
    return _firestore
        .collection('messages')
        .where('chatRoomId', isEqualTo: chatRoomId)
        .snapshots()
        .map((snapshot) {
      final messages = snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data()))
          .toList();
      messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return messages;
    });
  }

  Stream<List<MyUser>> getUsersStream() {
    return _firestore
        .collection('users')
        .where('id', isNotEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => MyUser.fromDocument(doc.data())).toList());
  }

  Future<void> _updateUserChatRooms(String userId, String chatRoomId) async {
    await _firestore.collection('users').doc(userId).update({
      'chatRooms': FieldValue.arrayUnion([chatRoomId]),
    });
  }

  Future<void> addParticipantToGroup(String chatRoomId, String userId) async {
    await _firestore.collection('chatRooms').doc(chatRoomId).update({
      'participants': FieldValue.arrayUnion([userId]),
      'unreadCount.$userId': 0,
    });

    await _updateUserChatRooms(userId, chatRoomId);
  }

  Future<void> removeParticipantFromGroup(String chatRoomId, String userId) async {
    await _firestore.collection('chatRooms').doc(chatRoomId).update({
      'participants': FieldValue.arrayRemove([userId]),
      'unreadCount.$userId': FieldValue.delete(),
    });

    await _firestore.collection('users').doc(userId).update({
      'chatRooms': FieldValue.arrayRemove([chatRoomId]),
    });
  }

  Stream<Map<String, int>> getGroupChatsOrderStream() {
    if (currentUserId.isEmpty) return Stream.value({});
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .map((snap) {
      if (!snap.exists) return <String, int>{};
      final data = snap.data();
      final raw = data?['groupChatsOrder'];
      if (raw == null) return <String, int>{};
      return Map<String, int>.from(raw as Map);
    });
  }

  Future<void> updateGroupChatImage(String chatRoomId, String imageUrl) async {
    await _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .update({'groupImage': imageUrl});
  }

  Future<void> updateGroupChatName(String chatRoomId, String newName) async {
    await _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .update({'name': newName});
  }

  /// Get a reply-to message document.
  Future<Map<String, dynamic>?> getReplyMessage(String chatRoomId, String messageId) async {
    final doc = await _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .doc(messageId)
        .get();
    if (!doc.exists) return null;
    return doc.data() as Map<String, dynamic>;
  }

  /// Get the other user's ID from a chat room.
  Future<String> getChatRoomOtherUserId(String chatRoomId, String currentUserId) async {
    final doc = await _firestore.collection('chatRooms').doc(chatRoomId).get();
    final participants = List<String>.from(doc['participants']);
    return participants.firstWhere((id) => id != currentUserId);
  }

  /// Get a post document by ID.
  Future<Map<String, dynamic>?> getPostById(String postId) async {
    final doc = await _firestore.collection('posts').doc(postId).get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>;
    data['postId'] = doc.id;
    return data;
  }

  /// Fetch a user's display name.
  Future<String> fetchUserName(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['name'] ?? 'Unknown User';
      }
      return 'User not found';
    } catch (e) {
      return 'Error';
    }
  }
}
