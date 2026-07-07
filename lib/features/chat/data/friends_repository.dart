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
  }) : _firestore = firestore,
       _auth = auth;

  String get currentUserId => _auth.currentUser?.uid ?? '';

  Future<List<Map<String, String>>> getBlockedFriends() async {
    try {
      final userDoc =
          await _firestore.collection('users').doc(currentUserId).get();
      if (!userDoc.exists) return [];
      final user = MyUser.fromDocument(userDoc.data()!);
      if (user.blocked == null || user.blocked!.isEmpty) return [];
      final blockedIds = user.blocked!;
      if (blockedIds.isEmpty) return [];
      List<QueryDocumentSnapshot<Map<String, dynamic>>> allDocs = [];
      List<Future<QuerySnapshot<Map<String, dynamic>>>> futures = [];
      for (var i = 0; i < blockedIds.length; i += 30) {
        final chunk = blockedIds.sublist(
            i, i + 30 > blockedIds.length ? blockedIds.length : i + 30);
        futures.add(_firestore
            .collection('users')
            .where('userId', whereIn: chunk)
            .get());
      }
      final snapshots = await Future.wait(futures);
      for (var snap in snapshots) {
        allDocs.addAll(snap.docs);
      }
      return allDocs
          .map(
            (doc) => {
              'userId': (doc['userId'] ?? '').toString(),
              'name': (doc['name'] ?? '').toString(),
              'url': (doc['url'] ?? '').toString(),
            },
          )
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
      final blocksQuery =
          await _firestore
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

      final userQuery =
          await _firestore
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

      final userQuery =
          await _firestore
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

      final followingRef1 = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(friendId);
      final followerRef1 = _firestore
          .collection('users')
          .doc(friendId)
          .collection('followers')
          .doc(currentUserId);
      final followingDoc1 = await followingRef1.get();
      if (followingDoc1.exists) {
        batch.delete(followingRef1);
        batch.delete(followerRef1);
        batch.update(currentUserDoc.reference, {
          'followingCount': FieldValue.increment(-1),
        });
        batch.update(_firestore.collection('users').doc(friendId), {
          'followerCount': FieldValue.increment(-1),
        });
      }

      final followingRef2 = _firestore
          .collection('users')
          .doc(friendId)
          .collection('following')
          .doc(currentUserId);
      final followerRef2 = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('followers')
          .doc(friendId);
      final followingDoc2 = await followingRef2.get();
      if (followingDoc2.exists) {
        batch.delete(followingRef2);
        batch.delete(followerRef2);
        batch.update(_firestore.collection('users').doc(friendId), {
          'followingCount': FieldValue.increment(-1),
        });
        batch.update(currentUserDoc.reference, {
          'followerCount': FieldValue.increment(-1),
        });
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

          List<MyUser> allFriends = [];
          List<Future<QuerySnapshot<Map<String, dynamic>>>> futures = [];
          for (var i = 0; i < user.friends.length; i += 30) {
            final chunk = user.friends.sublist(
                i, i + 30 > user.friends.length ? user.friends.length : i + 30);
            futures.add(_firestore
                .collection('users')
                .where('userId', whereIn: chunk)
                .get());
          }
          final snapshots = await Future.wait(futures);
          for (var snap in snapshots) {
            allFriends.addAll(
                snap.docs.map((doc) => MyUser.fromDocument(doc.data())));
          }

          return allFriends
              .where(
                (friend) =>
                    !(user.blocked?.contains(friend.userId) ?? false) &&
                    !(friend.blocked?.contains(user.userId) ?? false),
              )
              .toList();
        });
  }

  Future<List<MyUser>> getFriendsList({bool includeHidden = true}) async {
    final userDoc =
        await _firestore.collection('users').doc(currentUserId).get();
    if (!userDoc.exists) return <MyUser>[];
    final user = MyUser.fromDocument(userDoc.data()!);
    if (user.friends.isEmpty) return <MyUser>[];

    List<MyUser> allFriends = [];
    List<Future<QuerySnapshot<Map<String, dynamic>>>> futures = [];
    for (var i = 0; i < user.friends.length; i += 30) {
      final chunk = user.friends.sublist(
          i, i + 30 > user.friends.length ? user.friends.length : i + 30);
      futures.add(_firestore
          .collection('users')
          .where('userId', whereIn: chunk)
          .get());
    }
    final snapshots = await Future.wait(futures);
    for (var snap in snapshots) {
      allFriends.addAll(
          snap.docs.map((doc) => MyUser.fromDocument(doc.data())));
    }

    Set<String> hiddenIds = {};
    if (!includeHidden) {
      final hiddenSnap =
          await _firestore
              .collection('users')
              .doc(currentUserId)
              .collection('hiddenFriends')
              .get();
      hiddenIds = hiddenSnap.docs.map((d) => d.id).toSet();
    }

    return allFriends
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
      final friendsQuery =
          await _firestore
              .collection('users')
              .where('type', isEqualTo: 'brand')
              .get();
      return friendsQuery.docs
          .map((doc) => MyUser.fromDocument(doc.data()))
          .toList();
    });
  }

  Stream<int> getFriendsCountStream() {
    return _firestore.collection('users').doc(currentUserId).snapshots().map((
      snapshot,
    ) {
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

      final usersQuery =
          await _firestore
              .collection('users')
              .where('name', isGreaterThanOrEqualTo: query)
              .where('name', isLessThan: '${query}z')
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
      final userDoc =
          await _firestore.collection('users').doc(currentUserId).get();
      if (!userDoc.exists) return false;
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

      final otherUserDoc =
          await _firestore.collection('users').doc(userId).get();
      final otherUser = MyUser.fromDocument(otherUserDoc.data()!);

      final mutualFriendIds =
          currentUser.friends
              .where((friendId) => otherUser.friends.contains(friendId))
              .toList();

      if (mutualFriendIds.isEmpty) return [];

      List<MyUser> mutualFriends = [];
      List<Future<QuerySnapshot<Map<String, dynamic>>>> futures = [];
      for (var i = 0; i < mutualFriendIds.length; i += 30) {
        final chunk = mutualFriendIds.sublist(
            i, i + 30 > mutualFriendIds.length ? mutualFriendIds.length : i + 30);
        futures.add(_firestore
            .collection('users')
            .where('userId', whereIn: chunk)
            .get());
      }
      final snapshots = await Future.wait(futures);
      for (var snap in snapshots) {
        mutualFriends.addAll(
            snap.docs.map((doc) => MyUser.fromDocument(doc.data())));
      }

      return mutualFriends;
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

  // ─── Methods migrated from UI layer ──────────────────────────────────────

  /// Stream the current user's following IDs.
  Stream<Set<String>> getFollowingIdsStream() {
    final uid = currentUserId;
    if (uid.isEmpty) return Stream.value({});
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('following')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toSet());
  }

  /// Hide a friend by adding to hiddenFriends subcollection.
  Future<void> hideFriendById(String friendId) async {
    final uid = currentUserId;
    if (uid.isEmpty) return;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('hiddenFriends')
        .doc(friendId)
        .set({'hiddenAt': FieldValue.serverTimestamp()});
  }

  /// Unhide a friend.
  Future<void> unhideFriendById(String friendId) async {
    final uid = currentUserId;
    if (uid.isEmpty) return;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('hiddenFriends')
        .doc(friendId)
        .delete();
  }

  /// Get the alias for a friend, or null if none exists.
  Future<String?> getAlias(String friendId) async {
    final uid = currentUserId;
    if (uid.isEmpty) return null;
    final doc =
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('aliases')
            .doc(friendId)
            .get();
    return doc.data()?['alias'] as String?;
  }

  /// Set an alias for a friend.
  Future<void> setAlias(String friendId, String alias) async {
    final uid = currentUserId;
    if (uid.isEmpty) return;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('aliases')
        .doc(friendId)
        .set({'alias': alias});
  }

  /// Delete an alias for a friend.
  Future<void> deleteAlias(String friendId) async {
    final uid = currentUserId;
    if (uid.isEmpty) return;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('aliases')
        .doc(friendId)
        .delete();
  }

  /// Multi-field user search (name, email, phoneNumber).
  Future<List<MyUser>> searchUsersByAny(String query) async {
    if (query.trim().isEmpty) return [];
    final q = query.trim();
    final uid = currentUserId;
    if (uid.isEmpty) return [];
    final currentDoc = await _firestore.collection('users').doc(uid).get();
    final currentUser = MyUser.fromDocument(currentDoc.data()!);
    final friendIds = currentUser.friends;

    Future<List<MyUser>> runQuery(String field, String value) async {
      final snap =
          await _firestore
              .collection('users')
              .where(field, isGreaterThanOrEqualTo: value)
              .where(field, isLessThan: '${value}z')
              .limit(20)
              .get();
      return snap.docs
          .map((d) => MyUser.fromDocument(d.data()))
          .where((u) => u.userId != uid && !friendIds.contains(u.userId))
          .toList();
    }

    final results = await Future.wait([
      runQuery('name', q),
      runQuery('email', q.toLowerCase()),
      runQuery('phoneNumber', q),
    ]);

    final seen = <String>{};
    final merged = <MyUser>[];
    for (final list in results) {
      for (final user in list) {
        if (seen.add(user.userId)) merged.add(user);
      }
    }
    return merged;
  }

  // ─── Edit screen helper methods ──────────────────────────────────────────

  /// Stream hidden friend IDs.
  Stream<Set<String>> getHiddenIdsStream(String uid) {
    if (uid.isEmpty) return Stream.value({});
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('hiddenFriends')
        .snapshots()
        .map((s) => s.docs.map((d) => d.id).toSet());
  }

  /// Stream blocked user IDs.
  Stream<List<String>> getBlockedIdsStream(String uid) {
    if (uid.isEmpty) return Stream.value([]);
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((d) => List<String>.from(d.data()?['blocked'] ?? []));
  }

  /// Stream favorite order map.
  Stream<Map<String, int>> getFavoriteOrderStream(String uid) {
    if (uid.isEmpty) return Stream.value({});
    return _firestore.collection('users').doc(uid).snapshots().map((snap) {
      if (!snap.exists) return <String, int>{};
      final raw = snap.data()?['favoritesOrder'];
      if (raw == null) return <String, int>{};
      return Map<String, int>.from(raw as Map);
    });
  }

  /// Stream group chats order map.
  Stream<Map<String, int>> getGroupChatsOrderStream(String uid) {
    if (uid.isEmpty) return Stream.value({});
    return _firestore.collection('users').doc(uid).snapshots().map((snap) {
      if (!snap.exists) return <String, int>{};
      final raw = snap.data()?['groupChatsOrder'];
      if (raw == null) return <String, int>{};
      return Map<String, int>.from(raw as Map);
    });
  }

  /// Remove a favorite and delete order entry.
  Future<void> removeFavoriteAndOrder(String uid, String userId) async {
    await _firestore.collection('users').doc(uid).update({
      'favoritesOrder.$userId': FieldValue.delete(),
    });
  }

  /// Reorder favorites.
  Future<void> reorderFavorites(String uid, Map<String, int> orderMap) async {
    await _firestore.collection('users').doc(uid).update({
      'favoritesOrder': orderMap,
    });
  }

  /// Reorder group chats.
  Future<void> reorderGroupChats(String uid, Map<String, int> orderMap) async {
    await _firestore.collection('users').doc(uid).update({
      'groupChatsOrder': orderMap,
    });
  }

  /// Fetch blocked user documents.
  Future<List<MyUser>> fetchBlockedUsers(List<String> ids) async {
    if (ids.isEmpty) return [];
    final results = await Future.wait(
      ids.map((id) async {
        try {
          final doc = await _firestore.collection('users').doc(id).get();
          if (doc.exists) return MyUser.fromDocument(doc.data()!);
        } catch (_) {}
        return null;
      }),
    );
    return results.whereType<MyUser>().toList();
  }
}
