// services/friends_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/friend_request_model.dart';

class FriendsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser?.uid ?? '';

  // Send friend request
  Future<bool> sendFriendRequest(String receiverId) async {
    try {
      // Check if already friends
      final currentUserDoc =
          await _firestore.collection('users').doc(currentUserId).get();
      final currentUser = MyUser.fromDocument(currentUserDoc.data()!);

      if (currentUser.friends.contains(receiverId)) {
        throw Exception('Already friends');
      }

      // Check if request already sent
      if (currentUser.friendRequestsSent.contains(receiverId)) {
        throw Exception('Friend request already sent');
      }

      // Check if there's a pending request from the other user
      final receiverDoc =
          await _firestore.collection('users').doc(receiverId).get();
      final receiver = MyUser.fromDocument(receiverDoc.data()!);

      if (receiver.friendRequestsSent.contains(currentUserId)) {
        throw Exception('This user has already sent you a friend request');
      }

      // Get receiver's data
      final currentUserData = currentUser;
      final receiverData = receiver;

      // Create friend request
      final requestRef = _firestore.collection('friendRequests').doc();
      final friendRequest = FriendRequestModel(
        id: requestRef.id,
        senderId: currentUserId,
        senderName: currentUserData.name,
        senderProfileImage: currentUserData.url,
        receiverId: receiverId,
        receiverName: receiverData.name,
        createdAt: DateTime.now(),
      );

      // Use batch to ensure atomicity
      final batch = _firestore.batch();

      // Add friend request
      batch.set(requestRef, friendRequest.toMap());

      // Update sender's friendRequestsSent
      batch.update(_firestore.collection('users').doc(currentUserId), {
        'friendRequestsSent': FieldValue.arrayUnion([receiverId]),
      });

      // Update receiver's friendRequestsReceived
      batch.update(_firestore.collection('users').doc(receiverId), {
        'friendRequestsReceived': FieldValue.arrayUnion([currentUserId]),
      });

      await batch.commit();
      return true;
    } catch (e) {
      print('Error sending friend request: $e');
      return false;
    }
  }

  // Respond to friend request
  Future<bool> respondToFriendRequest(String requestId, bool accept) async {
    try {
      final requestDoc =
          await _firestore.collection('friendRequests').doc(requestId).get();
      final friendRequest = FriendRequestModel.fromMap(requestDoc.data()!);

      if (friendRequest.receiverId != currentUserId) {
        throw Exception('Unauthorized');
      }

      final batch = _firestore.batch();

      // Update friend request status
      batch.update(_firestore.collection('friendRequests').doc(requestId), {
        'status': accept ? 'accepted' : 'rejected',
        'respondedAt': DateTime.now().millisecondsSinceEpoch,
      });

      if (accept) {
        // Add to each other's friends list
        batch.update(_firestore.collection('users').doc(currentUserId), {
          'friends': FieldValue.arrayUnion([friendRequest.senderId]),
        });

        batch.update(
          _firestore.collection('users').doc(friendRequest.senderId),
          {
            'friends': FieldValue.arrayUnion([currentUserId]),
          },
        );
      }

      // Remove from pending lists
      batch.update(_firestore.collection('users').doc(currentUserId), {
        'friendRequestsReceived': FieldValue.arrayRemove([
          friendRequest.senderId,
        ]),
      });

      batch.update(_firestore.collection('users').doc(friendRequest.senderId), {
        'friendRequestsSent': FieldValue.arrayRemove([currentUserId]),
      });

      await batch.commit();
      return true;
    } catch (e) {
      print('Error responding to friend request: $e');
      return false;
    }
  }

  // Remove friend
  Future<bool> removeFriend(String friendId) async {
    try {
      final batch = _firestore.batch();

      // Remove from each other's friends list
      batch.update(_firestore.collection('users').doc(currentUserId), {
        'friends': FieldValue.arrayRemove([friendId]),
      });

      batch.update(_firestore.collection('users').doc(friendId), {
        'friends': FieldValue.arrayRemove([currentUserId]),
      });

      await batch.commit();
      return true;
    } catch (e) {
      print('Error removing friend: $e');
      return false;
    }
  }

  // Get friends stream
  Stream<List<MyUser>> getFriendsStream() {
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .asyncMap((userDoc) async {
          final user = MyUser.fromDocument(userDoc.data()!);
          if (user.friends.isEmpty) return <MyUser>[];

          final friendsQuery =
              await _firestore
                  .collection('users')
                  .where('id', whereIn: user.friends)
                  .get();

          return friendsQuery.docs
              .map((doc) => MyUser.fromDocument(doc.data()))
              .toList();
        });
  }

  // Get friend requests stream
  Stream<List<FriendRequestModel>> getFriendRequestsStream() {
    return _firestore
        .collection('friendRequests')
        .where('receiverId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => FriendRequestModel.fromMap(doc.data()))
                  .toList(),
        );
  }

  // Search users (excluding friends and pending requests)
  Future<List<MyUser>> searchUsers(String query) async {
    final currentUserDoc =
        await _firestore.collection('users').doc(currentUserId).get();
    final currentUser = MyUser.fromDocument(currentUserDoc.data()!);

    final usersQuery =
        await _firestore
            .collection('users')
            .where('name', isGreaterThanOrEqualTo: query)
            .where('name', isLessThan: query + 'z')
            .limit(20)
            .get();

    return usersQuery.docs
        .map((doc) => MyUser.fromDocument(doc.data()))
        .where(
          (user) =>
              user.userId != currentUserId &&
              !currentUser.friends.contains(user.userId) &&
              !currentUser.friendRequestsSent.contains(user.userId) &&
              !currentUser.friendRequestsReceived.contains(user.userId),
        )
        .toList();
  }

  // Check if users are friends
  Future<bool> areFriends(String userId) async {
    final userDoc =
        await _firestore.collection('users').doc(currentUserId).get();
    final user = MyUser.fromDocument(userDoc.data()!);
    return user.friends.contains(userId);
  }
}
