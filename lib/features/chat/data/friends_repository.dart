import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/firebase_providers.dart';

final friendsRepositoryProvider = Provider<FriendsRepository>((ref) {
  return FriendsRepository(
    firestore: ref.watch(firestoreProvider),
    auth: ref.watch(authProvider),
  );
});

class FriendsRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FriendsRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  String get currentUserId => _auth.currentUser?.uid ?? '';

  Future<List<Map<String, String>>> getBlockedFriends() async {
    try {
      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      if (!userDoc.exists) return [];
      final user = MyUser.fromDocument(userDoc.data()!);
      if (user.blocked == null || user.blocked!.isEmpty) return [];
      final blockedIds = user.blocked!;
      if (blockedIds.isEmpty) return [];
      final blockedQuery = await _firestore
          .collection('users')
          .where('userId', whereIn: blockedIds)
          .get();
      return blockedQuery.docs
          .map((doc) => {
                'userId': (doc['userId'] ?? '').toString(),
                'name': (doc['name'] ?? '').toString(),
                'url': (doc['url'] ?? '').toString(),
              })
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> unblockFriend(String userId) async {
    try {
      await _firestore.collection('users').doc(currentUserId).update({
        'blocked': FieldValue.arrayRemove([userId]),
      });
      final blocksQuery = await _firestore
          .collection('blocks')
          .where('blockedBy', isEqualTo: currentUserId)
          .where('blockedUserId', isEqualTo: userId)
          .get();
      for (final doc in blocksQuery.docs) {
        await doc.reference.delete();
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> addFriend(String friendName) async {
    try {
      final currentUserDoc =
          await _firestore.collection('users').doc(currentUserId).get();
      final currentUser = MyUser.fromDocument(currentUserDoc.data()!);

      if (currentUser.name == friendName) {
        throw Exception('Cannot add yourself as a friend');
      }

      final userQuery = await _firestore
          .collection('users')
          .where('name', isEqualTo: friendName)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        throw Exception('User not found');
      }

      final friendDoc = userQuery.docs.first;
      final friendId = friendDoc['userId'];

      if (currentUser.friends.contains(friendId)) {
        throw Exception('Already friends with this user');
      }

      final batch = _firestore.batch();
      batch.update(_firestore.collection('users').doc(currentUserId), {
        'friends': FieldValue.arrayUnion([friendId]),
      });
      batch.update(_firestore.collection('users').doc(friendId), {
        'friends': FieldValue.arrayUnion([currentUserId]),
      });

      await batch.commit();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> blockFriend(String friendName) async {
    try {
      final currentUserDoc =
          await _firestore.collection('users').doc(currentUserId).get();
      final currentUser = MyUser.fromDocument(currentUserDoc.data()!);

      if (currentUser.name == friendName) {
        throw Exception('Cannot block yourself');
      }

      final userQuery = await _firestore
          .collection('users')
          .where('name', isEqualTo: friendName)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        throw Exception('User not found');
      }

      final friendDoc = userQuery.docs.first;
      final friendId = friendDoc['userId'];
      if (currentUser.blocked!.contains(friendId)) {
        throw Exception('Already blocked this user');
      }

      final batch = _firestore.batch();

      batch.update(currentUserDoc.reference, {
        'blocked': FieldValue.arrayUnion([friendId]),
        'friends': FieldValue.arrayRemove([friendId]),
      });
      batch.update(_firestore.collection('users').doc(friendId), {
        'friends': FieldValue.arrayRemove([currentUserId]),
      });

      final blocksCollection = FirebaseFirestore.instance.collection('blocks');
      final newBlockRef = blocksCollection.doc();
      batch.set(newBlockRef, {
        'blockedUserId': friendId,
        'blockedBy': currentUser.userId,
        'blockId': newBlockRef.id,
      });

      final followingRef1 = _firestore.collection('users').doc(currentUserId).collection('following').doc(friendId);
      final followerRef1 = _firestore.collection('users').doc(friendId).collection('followers').doc(currentUserId);
      final followingDoc1 = await followingRef1.get();
      if (followingDoc1.exists) {
        batch.delete(followingRef1);
        batch.delete(followerRef1);
        batch.update(currentUserDoc.reference, {'followingCount': FieldValue.increment(-1)});
        batch.update(_firestore.collection('users').doc(friendId), {'followerCount': FieldValue.increment(-1)});
      }

      final followingRef2 = _firestore.collection('users').doc(friendId).collection('following').doc(currentUserId);
      final followerRef2 = _firestore.collection('users').doc(currentUserId).collection('followers').doc(friendId);
      final followingDoc2 = await followingRef2.get();
      if (followingDoc2.exists) {
        batch.delete(followingRef2);
        batch.delete(followerRef2);
        batch.update(_firestore.collection('users').doc(friendId), {'followingCount': FieldValue.increment(-1)});
        batch.update(currentUserDoc.reference, {'followerCount': FieldValue.increment(-1)});
      }

      final participants = [currentUserId, friendId]..sort();
      final chatRoomId = participants.join('_');
      batch.delete(_firestore.collection('chatRooms').doc(chatRoomId));

      batch.update(_firestore.collection('users').doc(currentUserId), {
        'chatRooms': FieldValue.arrayRemove([chatRoomId]),
      });
      batch.update(_firestore.collection('users').doc(friendId), {
        'chatRooms': FieldValue.arrayRemove([chatRoomId]),
      });

      await batch.commit();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeFriend(String friendId) async {
    try {
      final batch = _firestore.batch();
      batch.update(_firestore.collection('users').doc(currentUserId), {
        'friends': FieldValue.arrayRemove([friendId]),
      });
      batch.update(_firestore.collection('users').doc(friendId), {
        'friends': FieldValue.arrayRemove([currentUserId]),
      });

      final participants = [currentUserId, friendId]..sort();
      final chatRoomId = participants.join('_');
      batch.delete(_firestore.collection('chatRooms').doc(chatRoomId));

      batch.update(_firestore.collection('users').doc(currentUserId), {
        'chatRooms': FieldValue.arrayRemove([chatRoomId]),
      });
      batch.update(_firestore.collection('users').doc(friendId), {
        'chatRooms': FieldValue.arrayRemove([chatRoomId]),
      });

      await batch.commit();
      return true;
    } catch (e) {
      return false;
    }
  }

  Stream<List<MyUser>> getFriendsStream() {
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .asyncMap((userDoc) async {
      if (!userDoc.exists) return <MyUser>[];
      final user = MyUser.fromDocument(userDoc.data()!);
      if (user.friends.isEmpty) return <MyUser>[];

      final friendsQuery = await _firestore
          .collection('users')
          .where('userId', whereIn: user.friends)
          .get();

      return friendsQuery.docs
          .map((doc) => MyUser.fromDocument(doc.data()))
          .where(
            (friend) =>
                !(user.blocked?.contains(friend.userId) ?? false) &&
                !(friend.blocked?.contains(user.userId) ?? false),
          )
          .toList();
    });
  }

  Future<List<MyUser>> getFriendsList({bool includeHidden = true}) async {
    final userDoc = await _firestore.collection('users').doc(currentUserId).get();
    if (!userDoc.exists) return <MyUser>[];
    final user = MyUser.fromDocument(userDoc.data()!);
    if (user.friends.isEmpty) return <MyUser>[];

    final friendsQuery = await _firestore
        .collection('users')
        .where('userId', whereIn: user.friends)
        .get();

    Set<String> hiddenIds = {};
    if (!includeHidden) {
      final hiddenSnap = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('hiddenFriends')
          .get();
      hiddenIds = hiddenSnap.docs.map((d) => d.id).toSet();
    }

    return friendsQuery.docs
        .map((doc) => MyUser.fromDocument(doc.data()))
        .where(
          (friend) =>
              !(user.blocked?.contains(friend.userId) ?? false) &&
              !(friend.blocked?.contains(user.userId) ?? false) &&
              (includeHidden || !hiddenIds.contains(friend.userId)),
        )
        .toList();
  }

  Stream<List<MyUser>> getBrandsStream() {
    return _firestore.collection('users').snapshots().asyncMap((userDoc) async {
      final friendsQuery = await _firestore
          .collection('users')
          .where('type', isEqualTo: 'brand')
          .get();
      return friendsQuery.docs
          .map((doc) => MyUser.fromDocument(doc.data()))
          .toList();
    });
  }

  Stream<int> getFriendsCountStream() {
    return _firestore.collection('users').doc(currentUserId).snapshots().map((snapshot) {
      if (!snapshot.exists) return 0;
      final user = MyUser.fromDocument(snapshot.data()!);
      return user.friends.length;
    });
  }

  Future<List<MyUser>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final currentUserDoc =
          await _firestore.collection('users').doc(currentUserId).get();
      final currentUser = MyUser.fromDocument(currentUserDoc.data()!);

      final usersQuery = await _firestore
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
                !currentUser.friends.contains(user.userId),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> areFriends(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      if(!userDoc.exists) return false;
      final user = MyUser.fromDocument(userDoc.data()!);
      return user.friends.contains(userId);
    } catch (e) {
      return false;
    }
  }

  Future<List<MyUser>> getMutualFriends(String userId) async {
    try {
      final currentUserDoc =
          await _firestore.collection('users').doc(currentUserId).get();
      final currentUser = MyUser.fromDocument(currentUserDoc.data()!);

      final otherUserDoc = await _firestore.collection('users').doc(userId).get();
      final otherUser = MyUser.fromDocument(otherUserDoc.data()!);

      final mutualFriendIds = currentUser.friends
          .where((friendId) => otherUser.friends.contains(friendId))
          .toList();

      if (mutualFriendIds.isEmpty) return [];

      final mutualFriendsQuery = await _firestore
          .collection('users')
          .where('id', whereIn: mutualFriendIds)
          .get();

      return mutualFriendsQuery.docs
          .map((doc) => MyUser.fromDocument(doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

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
