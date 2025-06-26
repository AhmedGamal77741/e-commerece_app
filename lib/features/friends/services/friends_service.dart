// services/friends_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser?.uid ?? '';

  // Add friend directly without request
  Future<bool> addFriend(String friendId) async {
    try {
      // Prevent adding yourself as a friend
      if (friendId == currentUserId) {
        throw Exception('Cannot add yourself as a friend');
      }

      // Check if already friends
      final currentUserDoc =
          await _firestore.collection('users').doc(currentUserId).get();
      final currentUser = MyUser.fromDocument(currentUserDoc.data()!);

      if (currentUser.friends.contains(friendId)) {
        throw Exception('Already friends with this user');
      }

      // Check if friend exists
      final friendDoc =
          await _firestore.collection('users').doc(friendId).get();
      if (!friendDoc.exists) {
        throw Exception('User not found');
      }

      // Use batch to ensure atomicity
      final batch = _firestore.batch();

      // Add to current user's friends list
      batch.update(_firestore.collection('users').doc(currentUserId), {
        'friends': FieldValue.arrayUnion([friendId]),
      });

      // Add to friend's friends list
      batch.update(_firestore.collection('users').doc(friendId), {
        'friends': FieldValue.arrayUnion([currentUserId]),
      });

      // Create friendship activity/notification (optional)
      final activityRef = _firestore.collection('activities').doc();
      batch.set(activityRef, {
        'id': activityRef.id,
        'type': 'new_friend',
        'userId': friendId,
        'friendId': currentUserId,
        'friendName': currentUser.name,
        'friendProfileImage': currentUser.url,
        'message': '${currentUser.name} added you as a friend',
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      await batch.commit();
      return true;
    } catch (e) {
      print('Error adding friend: $e');
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
          if (!userDoc.exists) return <MyUser>[];

          final user = MyUser.fromDocument(userDoc.data()!);
          if (user.friends.isEmpty) return <MyUser>[];

          final friendsQuery =
              await _firestore
                  .collection('users')
                  .where('userId', whereIn: user.friends)
                  .get();

          return friendsQuery.docs
              .map((doc) => MyUser.fromDocument(doc.data()))
              .toList();
        });
  }

  // Get friends count
  Stream<int> getFriendsCountStream() {
    return _firestore.collection('users').doc(currentUserId).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) return 0;
      final user = MyUser.fromDocument(snapshot.data()!);
      return user.friends.length;
    });
  }

  // Search users (excluding current user and existing friends)
  Future<List<MyUser>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      // Get current user's friends list
      final currentUserDoc =
          await _firestore.collection('users').doc(currentUserId).get();
      final currentUser = MyUser.fromDocument(currentUserDoc.data()!);

      // Search by name (case-insensitive)
      final usersQuery =
          await _firestore
              .collection('users')
              .where('name', isGreaterThanOrEqualTo: query)
              .where('name', isLessThan: query + 'z')
              .limit(20)
              .get();

      // You could also search by email or username
      // final emailQuery = await _firestore
      //     .collection('users')
      //     .where('email', isGreaterThanOrEqualTo: query.toLowerCase())
      //     .where('email', isLessThan: query.toLowerCase() + 'z')
      //     .limit(20)
      //     .get();

      return usersQuery.docs
          .map((doc) => MyUser.fromDocument(doc.data()))
          .where(
            (user) =>
                user.userId != currentUserId &&
                !currentUser.friends.contains(user.userId),
          )
          .toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  // Check if users are friends
  Future<bool> areFriends(String userId) async {
    try {
      final userDoc =
          await _firestore.collection('users').doc(currentUserId).get();
      final user = MyUser.fromDocument(userDoc.data()!);
      return user.friends.contains(userId);
    } catch (e) {
      print('Error checking friendship: $e');
      return false;
    }
  }

  // Get mutual friends
  Future<List<MyUser>> getMutualFriends(String userId) async {
    try {
      // Get current user's friends
      final currentUserDoc =
          await _firestore.collection('users').doc(currentUserId).get();
      final currentUser = MyUser.fromDocument(currentUserDoc.data()!);

      // Get other user's friends
      final otherUserDoc =
          await _firestore.collection('users').doc(userId).get();
      final otherUser = MyUser.fromDocument(otherUserDoc.data()!);

      // Find mutual friends
      final mutualFriendIds =
          currentUser.friends
              .where((friendId) => otherUser.friends.contains(friendId))
              .toList();

      if (mutualFriendIds.isEmpty) return [];

      // Get mutual friends data
      final mutualFriendsQuery =
          await _firestore
              .collection('users')
              .where('id', whereIn: mutualFriendIds)
              .get();

      return mutualFriendsQuery.docs
          .map((doc) => MyUser.fromDocument(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting mutual friends: $e');
      return [];
    }
  }

  // Bulk add friends (useful for importing contacts)
  Future<Map<String, bool>> bulkAddFriends(List<String> friendIds) async {
    Map<String, bool> results = {};

    for (String friendId in friendIds) {
      try {
        final success = await addFriend(friendId);
        results[friendId] = success;
      } catch (e) {
        results[friendId] = false;
      }
    }

    return results;
  }
}
