import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:ecommerece_app/features/home/domain/feed_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchState {
  final List<Map<String, dynamic>> posts;
  final List<MyUser> users;
  final bool isLoading;

  SearchState({
    this.posts = const [],
    this.users = const [],
    this.isLoading = false,
  });

  SearchState copyWith({
    List<Map<String, dynamic>>? posts,
    List<MyUser>? users,
    bool? isLoading,
  }) {
    return SearchState(
      posts: posts ?? this.posts,
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SearchNotifier extends AutoDisposeAsyncNotifier<SearchState> {
  String _query = '';
  StreamSubscription? _postsSub;
  StreamSubscription? _usersSub;

  @override
  FutureOr<SearchState> build() async {
    _initStreams();
    return SearchState();
  }

  void updateQuery(String query) {
    if (_query != query) {
      _query = query.toLowerCase();
      _initStreams();
    }
  }

  void _initStreams() {
    _postsSub?.cancel();
    _usersSub?.cancel();
    
    if (_query.trim().isEmpty) {
      state = AsyncValue.data(SearchState(posts: [], users: []));
      return;
    }

    state = const AsyncValue.loading();
    _listenToData();
  }

  Future<void> _listenToData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final feedController = ref.read(feedControllerProvider.notifier);
    
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      final userData = userDoc.data() ?? {};
      final blockedUsers = List<String>.from(userData['blocked'] ?? []);
      final isPremium = userData['isSub'] == true;

      Set<String> followingSet = {};
      if (isPremium) {
        final followingSnapshot = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).collection('following').get();
        followingSet = followingSnapshot.docs.map((d) => d.id).toSet();
      }

      // We'll combine posts and users in a single state update for simplicity
      _postsSub = feedController.searchPostsStream().listen((postsSnapshot) async {
        final postsDocs = postsSnapshot.docs;
        final authorIds = postsDocs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['userId'] as String;
        }).toSet().toList();

        if (authorIds.isEmpty) {
          _updateStatePosts([]);
          return;
        }

        final authorsMap = await ref.read(authorsDataMapProvider(authorIds).future);

        final filteredPosts = postsDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final postAuthorId = data['userId'] as String;
          final authorData = authorsMap[postAuthorId] ?? {};

          if (blockedUsers.contains(postAuthorId)) return false;
          
          final authorBlockedUsers = List<dynamic>.from(authorData['blocked'] ?? []);
          if (authorBlockedUsers.contains(currentUser.uid)) return false;

          final postText = data['text']?.toString().toLowerCase() ?? '';
          if (!postText.contains(_query)) return false;

          final notInterestedBy = List<dynamic>.from(data['notInterestedBy'] ?? []);
          if (notInterestedBy.contains(currentUser.uid)) return false;

          if (postAuthorId == currentUser.uid) return true;

          final bool isPrivate = authorData['isPrivate'] ?? false;
          if (!isPrivate) return true;

          return followingSet.contains(postAuthorId);
        }).map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['postId'] = data['postId'] ?? doc.id;
          return data;
        }).toList();

        _updateStatePosts(filteredPosts);
      });

      _usersSub = feedController.searchUsersStream().listen((usersSnapshot) {
        final docs = usersSnapshot.docs;
        final filteredUsers = docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return MyUser.fromDocument(data);
        }).where((user) {
          if (blockedUsers.contains(user.userId)) return false;
          final userBlockedList = user.blocked ?? [];
          if (userBlockedList.contains(currentUser.uid)) return false;
          
          if (user.userId == currentUser.uid) return false;
          if (!user.name.toLowerCase().contains(_query)) return false;
          
          return true;
        }).toList();

        _updateStateUsers(filteredUsers);
      });

    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  void _updateStatePosts(List<Map<String, dynamic>> posts) {
    if (state.value != null) {
      state = AsyncValue.data(state.value!.copyWith(posts: posts));
    }
  }

  void _updateStateUsers(List<MyUser> users) {
    if (state.value != null) {
      state = AsyncValue.data(state.value!.copyWith(users: users));
    }
  }
}

final searchNotifierProvider = AutoDisposeAsyncNotifierProvider<SearchNotifier, SearchState>(SearchNotifier.new);
