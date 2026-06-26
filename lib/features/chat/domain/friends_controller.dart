import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
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

final friendsControllerProvider = Provider<FriendsController>((ref) {
  return FriendsController(friendsRepository: ref.watch(friendsRepositoryProvider));
});

class FriendsController {
  final FriendsRepository _friendsRepository;

  FriendsController({required FriendsRepository friendsRepository})
      : _friendsRepository = friendsRepository;

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
