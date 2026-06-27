import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
      effectiveBlockedUsers: effectiveBlockedUsers ?? this.effectiveBlockedUsers,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class FollowFeedNotifier extends AsyncNotifier<FollowFeedState> {
  StreamSubscription? _userSub;
  StreamSubscription? _followingSub;
  StreamSubscription? _hiddenFriendsSub;
  StreamSubscription? _categoriesSub;
  String? _selectedUserIdForCategories;

  @override
  FutureOr<FollowFeedState> build() {
    _initData();
    ref.onDispose(() {
      _userSub?.cancel();
      _followingSub?.cancel();
      _hiddenFriendsSub?.cancel();
      _categoriesSub?.cancel();
    });
    return FollowFeedState(isLoading: true);
  }

  void _initData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      state = AsyncValue.data(FollowFeedState());
      return;
    }

    _userSub = FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots().listen((userDoc) {
      final userData = userDoc.data() ?? {};
      final currentUser = MyUser.fromDocument(userData);
      final blockedUsers = List<String>.from(userData['blocked'] ?? []);

      _hiddenFriendsSub?.cancel();
      _hiddenFriendsSub = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('hiddenFriends').snapshots().listen((hiddenFriendsSnapshot) {
        final hiddenFriendsSet = hiddenFriendsSnapshot.docs.map((d) => d.id).toSet();
        final effectiveBlockedUsers = {...blockedUsers, ...hiddenFriendsSet}.toList();

        _updateState(currentUser: currentUser, effectiveBlockedUsers: effectiveBlockedUsers);
      });
    });

    _followingSub = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('following').snapshots().listen((followingSnapshot) async {
      final followingIds = followingSnapshot.docs.map((doc) => doc.id).toList();
      
      final currentState = state.value;
      final effectiveBlockedUsers = currentState?.effectiveBlockedUsers ?? [];
      
      final filteredIds = followingIds.where((id) => !effectiveBlockedUsers.contains(id)).toList();
      
      if (filteredIds.isEmpty) {
        _updateState(followingUsers: []);
        return;
      }

      final List<List<String>> chunks = [];
      for (var i = 0; i < filteredIds.length; i += 30) {
        chunks.add(filteredIds.sublist(i, i + 30 > filteredIds.length ? filteredIds.length : i + 30));
      }

      final List<MyUser> fetchedUsers = [];
      await Future.wait(
        chunks.map((chunk) async {
          final querySnapshot = await FirebaseFirestore.instance.collection('users').where('userId', whereIn: chunk).get();
          for (var doc in querySnapshot.docs) {
            final userData = doc.data();
            final user = MyUser.fromDocument(userData);
            final userBlockedList = List<dynamic>.from(userData['blocked'] ?? []);
            if (!userBlockedList.contains(user.userId)) {
              fetchedUsers.add(user);
            }
          }
        }),
      );

      fetchedUsers.sort((a, b) {
        if (a.lastPostCreatedAt == null && b.lastPostCreatedAt == null) return 0;
        if (a.lastPostCreatedAt == null) return 1;
        if (b.lastPostCreatedAt == null) return -1;
        return b.lastPostCreatedAt!.compareTo(a.lastPostCreatedAt!);
      });

      _updateState(followingUsers: fetchedUsers);
    });
  }

  void loadCategories(String userId) {
    if (_selectedUserIdForCategories == userId) return;
    _selectedUserIdForCategories = userId;

    _categoriesSub?.cancel();
    _categoriesSub = FirebaseFirestore.instance.collection('users').doc(userId).collection('categories').orderBy('order', descending: false).snapshots().listen((snapshot) {
      final categories = snapshot.docs.map((doc) {
        final data = doc.data();
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
  }) {
    if (state.value != null) {
      state = AsyncValue.data(state.value!.copyWith(
        currentUser: currentUser,
        followingUsers: followingUsers,
        categories: categories,
        effectiveBlockedUsers: effectiveBlockedUsers,
        isLoading: false,
      ));
    }
  }

  Future<void> unblockUser(String userId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'blocked': FieldValue.arrayRemove([userId]),
    });
  }
}

final followFeedNotifierProvider = AsyncNotifierProvider<FollowFeedNotifier, FollowFeedState>(FollowFeedNotifier.new);
