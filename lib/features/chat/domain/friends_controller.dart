import 'dart:async';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/friends_repository.dart';

final friendsProvider = StreamProvider<List<MyUser>>((ref) {
  final friendsRepository = ref.watch(friendsRepositoryProvider);
  return friendsRepository.getFriendsStream();
});

final friendsCountProvider = StreamProvider<int>((ref) {
  final friendsRepository = ref.watch(friendsRepositoryProvider);
  return friendsRepository.getFriendsCountStream();
});

final brandsProvider = StreamProvider<List<MyUser>>((ref) {
  final friendsRepository = ref.watch(friendsRepositoryProvider);
  return friendsRepository.getBrandsStream();
});

final aliasesProvider = StreamProvider<Map<String, String>>((ref) {
  return ref.watch(friendsControllerProvider.notifier).getAliasesStream();
});

final friendsControllerProvider = AsyncNotifierProvider<FriendsController, void>(() {
  return FriendsController();
});

class FriendsController extends AsyncNotifier<void> {
  late final FriendsRepository _friendsRepository;

  @override
  FutureOr<void> build() {
    _friendsRepository = ref.watch(friendsRepositoryProvider);
  }

  Stream<Set<String>> getHiddenIdsStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value({});
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('hiddenFriends')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toSet());
  }

  Stream<Map<String, String>> getAliasesStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value({});
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('aliases')
        .snapshots()
        .map((snap) {
          final map = <String, String>{};
          for (final doc in snap.docs) {
            final alias = doc.data()['alias'] as String?;
            if (alias != null && alias.isNotEmpty) {
              map[doc.id] = alias;
            }
          }
          return map;
        });
  }

  Future<List<Map<String, String>>> getBlockedFriends() {
    return _friendsRepository.getBlockedFriends();
  }

  Future<bool> unblockFriend(String userId) {
    return _friendsRepository.unblockFriend(userId);
  }

  Future<bool> addFriend(String friendName) {
    return _friendsRepository.addFriend(friendName);
  }

  Future<bool> blockFriend(String friendName) {
    return _friendsRepository.blockFriend(friendName);
  }

  Future<bool> removeFriend(String friendId) {
    return _friendsRepository.removeFriend(friendId);
  }

  Future<List<MyUser>> getFriendsList({bool includeHidden = true}) {
    return _friendsRepository.getFriendsList(includeHidden: includeHidden);
  }

  Future<List<MyUser>> searchUsers(String query) {
    return _friendsRepository.searchUsers(query);
  }

  Future<bool> areFriends(String userId) {
    return _friendsRepository.areFriends(userId);
  }

  Future<List<MyUser>> getMutualFriends(String userId) {
    return _friendsRepository.getMutualFriends(userId);
  }

  Future<Map<String, bool>> bulkAddFriends(List<String> friendIds) {
    return _friendsRepository.bulkAddFriends(friendIds);
  }

  Stream<List<MyUser>> getFriendsStream() {
    return _friendsRepository.getFriendsStream();
  }

  // ─── Methods migrated from UI layer ──────────────────────────────────────

  /// Stream the current user's following IDs.
  Stream<Set<String>> getFollowingIdsStream() =>
      _friendsRepository.getFollowingIdsStream();

  /// Hide a friend.
  Future<void> hideFriendById(String friendId) =>
      _friendsRepository.hideFriendById(friendId);

  /// Unhide a friend.
  Future<void> unhideFriendById(String friendId) =>
      _friendsRepository.unhideFriendById(friendId);

  /// Get display name (alias or actual name).
  Future<String> getDisplayName(String friendId, String fallbackName) async {
    final alias = await _friendsRepository.getAlias(friendId);
    return (alias != null && alias.isNotEmpty) ? alias : fallbackName;
  }

  /// Get alias for a friend.
  Future<String?> getAlias(String friendId) =>
      _friendsRepository.getAlias(friendId);

  /// Set an alias for a friend.
  Future<void> setAlias(String friendId, String alias) =>
      _friendsRepository.setAlias(friendId, alias);

  /// Delete an alias for a friend.
  Future<void> deleteAlias(String friendId) =>
      _friendsRepository.deleteAlias(friendId);

  /// Multi-field user search.
  Future<List<MyUser>> searchUsersByAny(String query) =>
      _friendsRepository.searchUsersByAny(query);

  // ─── Edit screen proxy methods ───────────────────────────────────────────

  Stream<Set<String>> getHiddenIdsStreamForUser(String uid) =>
      _friendsRepository.getHiddenIdsStream(uid);

  Stream<List<String>> getBlockedIdsStream(String uid) =>
      _friendsRepository.getBlockedIdsStream(uid);

  Stream<Map<String, int>> getFavoriteOrderStream(String uid) =>
      _friendsRepository.getFavoriteOrderStream(uid);

  Stream<Map<String, int>> getGroupChatsOrderStream(String uid) =>
      _friendsRepository.getGroupChatsOrderStream(uid);

  Future<void> removeFavoriteAndOrder(String uid, String userId) =>
      _friendsRepository.removeFavoriteAndOrder(uid, userId);

  Future<void> reorderFavorites(String uid, Map<String, int> orderMap) =>
      _friendsRepository.reorderFavorites(uid, orderMap);

  Future<void> reorderGroupChats(String uid, Map<String, int> orderMap) =>
      _friendsRepository.reorderGroupChats(uid, orderMap);

  Future<List<MyUser>> fetchBlockedUsers(List<String> ids) =>
      _friendsRepository.fetchBlockedUsers(ids);

  Future<void> hideUserFriend(String uid, String friendId) =>
      _friendsRepository.hideFriendById(friendId);

  Future<void> unhideUserFriend(String uid, String friendId) =>
      _friendsRepository.unhideFriendById(friendId);
}
