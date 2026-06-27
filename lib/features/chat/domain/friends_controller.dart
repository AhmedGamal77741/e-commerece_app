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
}
