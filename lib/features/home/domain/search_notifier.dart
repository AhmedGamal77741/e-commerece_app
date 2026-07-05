import 'dart:async';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:ecommerece_app/features/home/domain/feed_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

class SearchState {
  final List<Map<String, dynamic>> posts;
  final List<MyUser> users;
  final bool isLoading;
  final String query;

  SearchState({
    this.posts = const [],
    this.users = const [],
    this.isLoading = false,
    this.query = '',
  });

  SearchState copyWith({
    List<Map<String, dynamic>>? posts,
    List<MyUser>? users,
    bool? isLoading,
    String? query,
  }) {
    return SearchState(
      posts: posts ?? this.posts,
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      query: query ?? this.query,
    );
  }
}

class SearchNotifier extends AsyncNotifier<SearchState> {
  String _query = '';
  StreamSubscription? _postsSub;
  StreamSubscription? _usersSub;

  List<String> _cachedBlockedUsers = const [];
  Set<String> _cachedHiddenFriends = const {};
  Set<String> _cachedFollowingSet = const {};

  @override
  FutureOr<SearchState> build() {
    ref.onDispose(() {
      _postsSub?.cancel();
      _usersSub?.cancel();
    });

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId != null) {
      ref.listen(currentUserProfileProvider, (previous, next) {
        if (next.value != null) {
          _cachedBlockedUsers = List<String>.from(next.value!['blocked'] ?? []);
        }
      }, fireImmediately: true);

      ref.listen(hiddenFriendsListProvider(currentUserId), (previous, next) {
        if (next.value != null) {
          _cachedHiddenFriends = next.value!.toSet();
        }
      }, fireImmediately: true);

      ref.listen(followingSetProvider(currentUserId), (previous, next) {
        if (next.value != null) {
          _cachedFollowingSet = next.value!.toSet();
        }
      }, fireImmediately: true);
    }

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
      state = AsyncValue.data(SearchState(posts: [], users: [], query: _query));
      return;
    }

    state = AsyncValue.data(
      (state.value ?? SearchState()).copyWith(isLoading: true, query: _query),
    );
    _listenToData();
  }

  Future<void> _listenToData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final String? currentUserId = currentUser?.uid;
    final String currentQuery = _query;

    final feedController = ref.read(feedControllerProvider.notifier);

    if (currentQuery != _query) return;

    try {
      // 1. Subscribe to posts search stream
      _postsSub = feedController.searchPostsStream().listen((postsSnapshot) async {
        if (currentQuery != _query) return;

        final postsDocs = postsSnapshot.docs;
        final authorIds = postsDocs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>?;
              return (data?['userId'] ?? '').toString();
            })
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList();

        if (authorIds.isEmpty) {
          if (currentQuery == _query) {
            _updateStatePosts([]);
          }
          return;
        }

        // Fetch authors in parallel using feedController's optimized loadUser (reads cache or Firestore once)
        final List<MyUser> authors = await Future.wait(
          authorIds.map((id) => feedController.loadUser(id)),
        );

        if (currentQuery != _query) return;

        final Map<String, MyUser> authorsMap = {
          for (final author in authors) author.userId: author
        };

        final filteredPosts = postsDocs
            .where((doc) {
              final data = doc.data() as Map<String, dynamic>?;
              if (data == null) return false;

              final postAuthorId = (data['userId'] ?? '').toString();
              if (postAuthorId.isEmpty) return false;

              final author = authorsMap[postAuthorId];

              // Block lists & hidden friends filtering
              if (_cachedBlockedUsers.contains(postAuthorId)) return false;
              if (_cachedHiddenFriends.contains(postAuthorId)) return false;

              if (currentUserId != null && author != null) {
                final authorBlockedUsers = author.blocked ?? [];
                if (authorBlockedUsers.contains(currentUserId)) {
                  return false;
                }
              }

              // Text filter
              final postText = data['text']?.toString().toLowerCase() ?? '';
              if (!postText.contains(currentQuery)) return false;

              // Interest/Privacy filters
              if (currentUserId != null) {
                final notInterestedBy = List<dynamic>.from(data['notInterestedBy'] ?? []);
                if (notInterestedBy.contains(currentUserId)) return false;

                if (postAuthorId == currentUserId) return true;
              }

              final bool isPrivate = author?.isPrivate ?? false;
              if (!isPrivate) return true;

              return _cachedFollowingSet.contains(postAuthorId);
            })
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>? ?? {};
              final mapped = Map<String, dynamic>.from(data);
              mapped['postId'] = mapped['postId'] ?? doc.id;
              return mapped;
            })
            .toList();

        if (currentQuery == _query) {
          _updateStatePosts(filteredPosts);
        }
      });

      // 2. Subscribe to users search stream
      _usersSub = feedController.searchUsersStream().listen((usersSnapshot) {
        if (currentQuery != _query) return;

        final docs = usersSnapshot.docs;
        final filteredUsers = docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>? ?? {};
              return MyUser.fromDocument(data);
            })
            .where((user) {
              if (user.userId.isEmpty) return false;
              if (_cachedBlockedUsers.contains(user.userId)) return false;
              if (_cachedHiddenFriends.contains(user.userId)) return false;
              
              if (currentUserId != null) {
                final userBlockedList = user.blocked ?? [];
                if (userBlockedList.contains(currentUserId)) return false;
                if (user.userId == currentUserId) return false;
              } else {
                if (user.isPrivate) return false;
              }

              if (!user.name.toLowerCase().contains(currentQuery)) return false;

              return true;
            })
            .toList();

        if (currentQuery == _query) {
          _updateStateUsers(filteredUsers);
        }
      });
    } catch (e) {
      if (currentQuery == _query) {
        state = AsyncValue.error(e, StackTrace.current);
      }
    }
  }

  void _updateStatePosts(List<Map<String, dynamic>> posts) {
    if (state.value != null) {
      state = AsyncValue.data(
        state.value!.copyWith(posts: posts, isLoading: false),
      );
    }
  }

  void _updateStateUsers(List<MyUser> users) {
    if (state.value != null) {
      state = AsyncValue.data(
        state.value!.copyWith(users: users, isLoading: false),
      );
    }
  }
}

final searchNotifierProvider =
    AsyncNotifierProvider<SearchNotifier, SearchState>(SearchNotifier.new);
