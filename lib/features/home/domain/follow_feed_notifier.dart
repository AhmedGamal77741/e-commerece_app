import 'dart:async';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:ecommerece_app/features/home/data/feed_repository.dart';
import 'package:ecommerece_app/core/providers/firebase_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FollowFeedState {
  final MyUser? currentUser;
  final List<MyUser> followingUsers;
  final List<Map<String, dynamic>> categories;
  final List<String> effectiveBlockedUsers;
  final bool isLoading;

  FollowFeedState({
    this.currentUser,
    this.followingUsers = const [],
    this.categories = const [],
    this.effectiveBlockedUsers = const [],
    this.isLoading = false,
  });

  FollowFeedState copyWith({
    MyUser? currentUser,
    List<MyUser>? followingUsers,
    List<Map<String, dynamic>>? categories,
    List<String>? effectiveBlockedUsers,
    bool? isLoading,
  }) {
    return FollowFeedState(
      currentUser: currentUser ?? this.currentUser,
      followingUsers: followingUsers ?? this.followingUsers,
      categories: categories ?? this.categories,
      effectiveBlockedUsers:
          effectiveBlockedUsers ?? this.effectiveBlockedUsers,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class FollowFeedNotifier extends AsyncNotifier<FollowFeedState> {
  StreamSubscription? _userSub;
  StreamSubscription? _followingSub;
  StreamSubscription? _hiddenFriendsSub;
  StreamSubscription? _categoriesSub;

  final Map<int, StreamSubscription> _chunkSubs = {};
  final Map<String, MyUser> _fetchedUsersMap = {};
  Timer? _debounceTimer;

  String? _selectedUserIdForCategories;
  List<String> _currentFollowingIds = [];

  @override
  FutureOr<FollowFeedState> build() {
    final user = ref.watch(authStateProvider).value;

    ref.onDispose(() {
      _cancelAllSubscriptions();
    });

    if (user == null) {
      return FollowFeedState();
    }

    _initData(user.uid);
    return FollowFeedState(isLoading: true);
  }

  void _cancelAllSubscriptions() {
    _userSub?.cancel();
    _followingSub?.cancel();
    _hiddenFriendsSub?.cancel();
    _categoriesSub?.cancel();
    _cancelChunkSubs();
    _debounceTimer?.cancel();
  }

  void _cancelChunkSubs() {
    for (final sub in _chunkSubs.values) {
      sub.cancel();
    }
    _chunkSubs.clear();
  }

  void _initData(String uid) {
    final repo = ref.read(feedRepositoryProvider);

    _userSub = repo.getCurrentUserStream(uid).listen((userDoc) {
      final userData = userDoc.data() as Map<String, dynamic>? ?? {};
      final currentUser = MyUser.fromDocument(userData);
      final blockedUsers = List<String>.from(userData['blocked'] ?? []);

      _hiddenFriendsSub?.cancel();
      _hiddenFriendsSub = repo.getHiddenFriendsStream(uid).listen((
        hiddenFriendsSnapshot,
      ) {
        final hiddenFriendsSet =
            hiddenFriendsSnapshot.docs.map((d) => d.id).toSet();
        final effectiveBlockedUsers =
            {...blockedUsers, ...hiddenFriendsSet}.toList();

        _updateState(
          currentUser: currentUser,
          effectiveBlockedUsers: effectiveBlockedUsers,
        );
        _refreshFollowingList();
      });
    });

    _followingSub = repo.getFollowingStreamForUser(uid).listen((
      followingSnapshot,
    ) {
      final followingIds = followingSnapshot.docs.map((doc) => doc.id).toList();
      _currentFollowingIds = followingIds;
      _refreshFollowingList();
    });
  }

  void _refreshFollowingList() {
    final currentState = state.value;
    if (currentState == null) return;

    final effectiveBlockedUsers = currentState.effectiveBlockedUsers;
    final filteredIds =
        _currentFollowingIds
            .where((id) => !effectiveBlockedUsers.contains(id))
            .toList();

    if (filteredIds.isEmpty) {
      _cancelChunkSubs();
      _fetchedUsersMap.clear();
      _emitAggregatedUsers();
      return;
    }

    final List<List<String>> chunks = [];
    for (var i = 0; i < filteredIds.length; i += 30) {
      chunks.add(
        filteredIds.sublist(
          i,
          i + 30 > filteredIds.length ? filteredIds.length : i + 30,
        ),
      );
    }

    _cancelChunkSubs();
    _fetchedUsersMap.removeWhere((key, value) => !filteredIds.contains(key));

    final repo = ref.read(feedRepositoryProvider);

    for (int i = 0; i < chunks.length; i++) {
      _chunkSubs[i] = repo.getUsersChunkStream(chunks[i]).listen((
        querySnapshot,
      ) {
        bool changed = false;
        for (var doc in querySnapshot.docs) {
          final userData = doc.data() as Map<String, dynamic>;
          final user = MyUser.fromDocument(userData);
          final userBlockedList = List<dynamic>.from(userData['blocked'] ?? []);

          if (!userBlockedList.contains(user.userId)) {
            _fetchedUsersMap[user.userId] = user;
            changed = true;
          } else if (_fetchedUsersMap.containsKey(user.userId)) {
            _fetchedUsersMap.remove(user.userId);
            changed = true;
          }
        }

        if (changed) {
          _debounceEmission();
        }
      });
    }
  }

  void _debounceEmission() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      _emitAggregatedUsers();
    });
  }

  void _emitAggregatedUsers() {
    final usersList = _fetchedUsersMap.values.toList();

    usersList.sort((a, b) {
      if (a.lastPostCreatedAt == null && b.lastPostCreatedAt == null) return 0;
      if (a.lastPostCreatedAt == null) return 1;
      if (b.lastPostCreatedAt == null) return -1;
      return b.lastPostCreatedAt!.compareTo(a.lastPostCreatedAt!);
    });

    _updateState(followingUsers: usersList, isLoading: false);
  }

  void loadCategories(String userId) {
    if (_selectedUserIdForCategories == userId) return;
    _selectedUserIdForCategories = userId;

    final repo = ref.read(feedRepositoryProvider);

    _categoriesSub?.cancel();
    _categoriesSub = repo.getUserCategoriesStream(userId).listen((snapshot) {
      final categories =
          snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          }).toList();
      _updateState(categories: categories);
    });
  }

  void _updateState({
    MyUser? currentUser,
    List<MyUser>? followingUsers,
    List<Map<String, dynamic>>? categories,
    List<String>? effectiveBlockedUsers,
    bool? isLoading,
  }) {
    if (state.value != null) {
      state = AsyncValue.data(
        state.value!.copyWith(
          currentUser: currentUser,
          followingUsers: followingUsers,
          categories: categories,
          effectiveBlockedUsers: effectiveBlockedUsers,
          isLoading: isLoading ?? state.value!.isLoading,
        ),
      );
    }
  }

  Future<void> unblockUser(String userId) async {
    final repo = ref.read(feedRepositoryProvider);
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    await repo.unblockUser(userIdToUnblock: userId);
  }
}

final followFeedNotifierProvider =
    AsyncNotifierProvider<FollowFeedNotifier, FollowFeedState>(
      FollowFeedNotifier.new,
    );
