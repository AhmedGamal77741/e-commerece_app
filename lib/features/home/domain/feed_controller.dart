import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/core/models/product_model.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:ecommerece_app/features/home/models/comment_model.dart';
import 'package:ecommerece_app/core/providers/firebase_providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerece_app/features/home/data/feed_repository.dart';
import 'package:image_picker/image_picker.dart';

// Stream Providers for reactive feed data
final userProfileDocProvider = StreamProvider.family<DocumentSnapshot?, String>(
  (ref, userId) {
    return ref.watch(feedRepositoryProvider).getUserStream(userId);
  },
);

final hiddenFriendsListProvider = StreamProvider.family<List<String>, String>((
  ref,
  userId,
) {
  return ref
      .watch(feedRepositoryProvider)
      .getHiddenFriendsStream(userId)
      .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
});

final followingSetProvider = StreamProvider.family<Set<String>, String>((
  ref,
  userId,
) {
  return ref
      .watch(feedRepositoryProvider)
      .getFollowingStreamForUser(userId)
      .map((snapshot) {
        final set = <String>{};
        for (var doc in snapshot.docs) {
          final uid = doc.get('userId') as String?;
          if (uid != null) set.add(uid);
        }
        return set;
      });
});

final allPostsStreamProvider = StreamProvider<List<QueryDocumentSnapshot>>((
  ref,
) {
  return ref
      .watch(feedRepositoryProvider)
      .searchPostsStream()
      .map((snapshot) => snapshot.docs);
});

final authorsDataMapProvider =
    StreamProvider.family<Map<String, Map<String, dynamic>>, String>((
      ref,
      authorIdsJoined,
    ) {
      final authorIds = authorIdsJoined.isEmpty ? <String>[] : authorIdsJoined.split(',');
      return ref
          .watch(feedRepositoryProvider)
          .getAuthorsDataStreamRealtime(authorIds);
    });

final followerCountProvider = FutureProvider.family<int, String>((ref, userId) async {
  if (userId.isEmpty) return 0;
  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('followers')
      .count()
      .get();
  return snapshot.count ?? 0;
});

final isFollowingProvider = StreamProvider.family<bool, String>((ref, targetUserId) {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  if (currentUserId == null) return Stream.value(false);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(currentUserId)
      .collection('following')
      .doc(targetUserId)
      .snapshots()
      .map((snapshot) => snapshot.exists);
});

final hasFollowRequestProvider = StreamProvider.family<bool, String>((ref, targetUserId) {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  if (currentUserId == null) return Stream.value(false);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(targetUserId)
      .collection('followRequests')
      .doc(currentUserId)
      .snapshots()
      .map((snapshot) => snapshot.exists);
});

/// Stable real-time stream for the currently logged-in user's profile document.
/// Used by HomeFAB and other widgets that need to react to isSub / profile changes.
final currentUserProfileProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(null);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((doc) => doc.data());
});

/// Stable real-time stream for whether the current user has any unread notifications.
final hasUnreadNotificationsProvider = StreamProvider<bool>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(false);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('notifications')
      .where('isRead', isEqualTo: false)
      .limit(1)
      .snapshots()
      .map((snapshot) => snapshot.docs.isNotEmpty);
});

final feedControllerProvider =
    AsyncNotifierProvider<FeedController, List<Map<String, dynamic>>>(
      FeedController.new,
    );

class FeedController extends AsyncNotifier<List<Map<String, dynamic>>> {
  final Map<String, List<Comment>> _comments = {};
  final Map<String, MyUser> _users = {};
  final Set<String> _loadingCommentPosts = {};

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FeedRepository get _repository => ref.read(feedRepositoryProvider);

  bool get hasMore => false;

  @override
  FutureOr<List<Map<String, dynamic>>> build() async {
    // Only watch authStateProvider to trigger rebuild on login/logout
    ref.watch(authStateProvider);

    return _fetchPage();
  }

  Future<List<Map<String, dynamic>>> _fetchPage() async {
    final user = ref.read(authStateProvider).value;

    final postsSnapshot = await _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .get();

    if (postsSnapshot.docs.isEmpty) {
      return [];
    }

    final postsDocs = postsSnapshot.docs;

    final authorIds = <String>{};
    for (var doc in postsDocs) {
      final data = doc.data();
      authorIds.add(data['userId'] as String);
    }

    final authorIdsList = authorIds
        .where((id) => id.isNotEmpty && !_users.containsKey(id))
        .toList();

    // Build author chunk futures
    final List<Future<QuerySnapshot>> authorChunkFutures = [];
    for (var i = 0; i < authorIdsList.length; i += 10) {
      final chunk = authorIdsList.sublist(
        i,
        i + 10 > authorIdsList.length ? authorIdsList.length : i + 10,
      );
      authorChunkFutures.add(
        _firestore.collection('users').where(FieldPath.documentId, whereIn: chunk).get(),
      );
    }

    // For authenticated users, fire user-data queries in parallel with author chunks
    Future<DocumentSnapshot>? userDocFuture;
    Future<QuerySnapshot>? hiddenFriendsFuture;

    if (user != null) {
      userDocFuture = _firestore.collection('users').doc(user.uid).get();
      hiddenFriendsFuture = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('hiddenFriends')
          .get();
    }

    // Await all author chunks in parallel
    final authorsMap = <String, Map<String, dynamic>>{};
    _users.forEach((key, value) {
      authorsMap[key] = value.toDocument();
    });

    if (authorChunkFutures.isNotEmpty) {
      final results = await Future.wait(authorChunkFutures);
      for (final snapshot in results) {
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          authorsMap[doc.id] = data;
          _users[doc.id] = MyUser.fromDocument(data);
        }
      }
    }

    if (user == null) {
      // Guest feed
      final guestPosts = postsDocs
          .where((doc) {
            final data = doc.data();
            final authorData = authorsMap[data['userId'] as String] ?? {};
            return (authorData['isPrivate'] ?? false) == false;
          })
          .map((doc) {
            final data = doc.data();
            data['postId'] = data['postId'] ?? doc.id;
            return data;
          })
          .toList();
      return guestPosts;
    }

    // Await user doc + hiddenFriends (already in-flight in parallel with author chunks)
    final userDoc = await userDocFuture!;
    final userData = userDoc.data() as Map<String, dynamic>?;
    if (userData == null) return [];

    _users[user.uid] = MyUser.fromDocument(userData);

    final blockedUsers = List<String>.from(userData['blocked'] ?? []);
    final isSub = userData['isSub'] ?? false;

    final hiddenFriendsSnapshot = await hiddenFriendsFuture!;
    final hiddenFriends = hiddenFriendsSnapshot.docs.map((doc) => doc.id).toList();

    Set<String> followingSet = {};
    if (isSub) {
      final followingSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('following')
          .get();
      for (var doc in followingSnapshot.docs) {
        final uid = doc.get('userId') as String?;
        if (uid != null) followingSet.add(uid);
      }
    }


    final authPosts = postsDocs
        .where((doc) {
          final data = doc.data();
          final postAuthorId = data['userId'] as String;

          if (postAuthorId == user.uid) return false;
          if (blockedUsers.contains(postAuthorId)) return false;
          if (hiddenFriends.contains(postAuthorId)) return false;

          final authorData = authorsMap[postAuthorId] ?? {};
          final authorBlockedUsers = List<dynamic>.from(
            authorData['blocked'] ?? [],
          );
          if (authorBlockedUsers.contains(user.uid)) return false;

          final notInterestedBy = List<dynamic>.from(
            data['notInterestedBy'] ?? [],
          );
          if (notInterestedBy.contains(user.uid)) return false;

          final bool isPrivate = authorData['isPrivate'] ?? false;
          if (!isPrivate) return true;

          if (isSub) {
            return followingSet.contains(postAuthorId);
          }
          return false;
        })
        .map((doc) {
          final data = doc.data();
          data['postId'] = data['postId'] ?? doc.id;
          return data;
        })
        .toList();
    return authPosts;
  }

  Future<void> fetchNextPage() async {}

  // Getters for comments and users (kept for compatibility with other files)
  List<Comment> getComments(String postId) {
    final comments = _comments[postId] ?? [];
    return comments.where((c) {
      if (c.createdAt is Timestamp) {
        final ts = c.createdAt as Timestamp;
        return ts.seconds > 0;
      }
      return false;
    }).toList();
  }

  bool isLoadingComments(String postId) =>
      _loadingCommentPosts.contains(postId);
  MyUser? getUser(String userId) => _users[userId];

  // Dummy implementations to prevent other files from crashing during sub-phase
  bool hasPostChanged(String postId) => false;
  void resetListening() {}
  void startListening() {}

  // ---------------------------------------------------------------------------
  // Proxy methods delegating to FeedRepository
  // ---------------------------------------------------------------------------
  Stream<QuerySnapshot> getNotificationsStream(String userId) =>
      _repository.getNotificationsStream(userId);
  Stream<QuerySnapshot> getUnreadNotificationsStream(String userId) =>
      _repository.getUnreadNotificationsStream(userId);
  Stream<QuerySnapshot> getHiddenFriendsStream(String userId) =>
      _repository.getHiddenFriendsStream(userId);
  Future<void> markAllNotificationsAsRead() =>
      _repository.markAllNotificationsAsRead();
  Stream<DocumentSnapshot> getUserStream(String userId) =>
      _repository.getUserStream(userId);
  Stream<QuerySnapshot> searchUsersStream() => _repository.searchUsersStream();
  Stream<QuerySnapshot> searchPostsStream() => _repository.searchPostsStream();
  Stream<Map<String, Map<String, dynamic>>> getAuthorsDataStreamRealtime(
    List<String> authorIds,
  ) => _repository.getAuthorsDataStreamRealtime(authorIds);
  Future<void> sendFollowRequest(String targetUserId) =>
      _repository.sendFollowRequest(targetUserId);
  Future<void> cancelFollowRequest(String targetUserId) =>
      _repository.cancelFollowRequest(targetUserId);
  Stream<QuerySnapshot> getFollowRequestsStream(String targetUserId) =>
      _repository.getFollowRequestsStream(targetUserId);
  Stream<QuerySnapshot> getFollowingStreamForUser(String userId) =>
      _repository.getFollowingStreamForUser(userId);
  Stream<DocumentSnapshot> getFollowingDocStream(
    String currentUserId,
    String targetUserId,
  ) => _repository.getFollowingDocStream(currentUserId, targetUserId);
  Stream<DocumentSnapshot> getFollowRequestDocStream(
    String targetUserId,
    String currentUserId,
  ) => _repository.getFollowRequestDocStream(targetUserId, currentUserId);
  Stream<QuerySnapshot> getUserCategoriesStream(String userId) =>
      _repository.getUserCategoriesStream(userId);
  Stream<QuerySnapshot> getUserPostsStream(
    String userId, {
    String? categoryId,
  }) => _repository.getUserPostsStream(userId, categoryId: categoryId);
  Future<MyUser> getUserProfile(String userId) => _repository.getUser(userId);

  Future<void> markPostNotInterested({required String postId}) async {
    await _repository.markPostNotInterested(postId: postId);
  }

  Future<void> blockUser({required String userIdToBlock}) async {
    await _repository.blockUser(userIdToBlock: userIdToBlock);
  }

  Future<void> unblockUser({required String userIdToUnblock}) =>
      _repository.unblockUser(userIdToUnblock: userIdToUnblock);
  Future<void> reportUser({
    required String reportedUserId,
    required String postId,
  }) => _repository.reportUser(reportedUserId: reportedUserId, postId: postId);
  Future<void> uploadPost({
    required String text,
    required List<String> imgUrls,
    String? categoryId,
  }) => _repository.uploadPost(
    text: text,
    imgUrls: imgUrls,
    categoryId: categoryId,
  );
  Future<void> updatePost({
    required String postId,
    required String text,
    required List<String> networkImgUrls,
    required List<XFile> newImages,
    String? categoryId,
  }) => _repository.updatePost(
    postId: postId,
    text: text,
    networkImgUrls: networkImgUrls,
    newImages: newImages,
    categoryId: categoryId,
  );
  Future<void> deletePost({required String postId}) => 
      _repository.deletePost(postId: postId);
  Future<String> uploadImageToFirebaseStorageHome() =>
      _repository.uploadImageToFirebaseStorageHome();
  Future<List<String>> uploadMultipleImagesToFirebaseHome() =>
      _repository.uploadMultipleImagesToFirebaseHome();
  Future<String> uploadSingleImageToFirebase(
    XFile image,
    int index, {
    Function(double)? onProgress,
  }) => _repository.uploadSingleImageToFirebase(
    image,
    index,
    onProgress: onProgress,
  );
  Future<void> migrateLastPostCreatedAt() =>
      _repository.migrateLastPostCreatedAt();

  Future<void> loadComments(String postId) async {
    if (_loadingCommentPosts.contains(postId)) return;

    _loadingCommentPosts.add(postId);
    // Since we don't have notifyListeners, Riverpod recommends re-assigning state or just using local state.
    // However, for compatibility with comments.dart in this phase, we keep it simple.

    try {
      final commentsSnapshot =
          await _firestore
              .collection('posts')
              .doc(postId)
              .collection('comments')
              .orderBy('createdAt', descending: true)
              .get();

      final comments =
          commentsSnapshot.docs
              .map((doc) => Comment.fromFirestore(doc))
              .toList();
      _comments[postId] = comments;

      final userIds =
          comments.map((comment) => comment.userId).toSet().toList();
      for (final userId in userIds) {
        if (!_users.containsKey(userId)) {
          try {
            await loadUser(userId);
            // ignore: empty_catches
          } catch (e) {}
        }
      }
    } finally {
      _loadingCommentPosts.remove(postId);
    }
  }

  Future<void> addToNotInterested(String postId) async {
    try {
      final currentUser = _auth.currentUser;
      final postRef = _firestore.collection('posts').doc(postId);
      await postRef.update({
        'notInterestedBy': FieldValue.arrayUnion([currentUser!.uid]),
      });
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void listenToComments(String postId) {
    _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
          final comments =
              snapshot.docs.map((doc) => Comment.fromFirestore(doc)).toList();
          _comments[postId] = comments;

          for (final comment in comments) {
            if (!_users.containsKey(comment.userId)) {
              loadUser(comment.userId);
            }
          }
        });
  }

  Future<void> addComment(
    String postId,
    String text, {
    String? imageUrl,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    MyUser? userData = _users[currentUser.uid];
    if (userData == null) {
      try {
        userData = await loadUser(currentUser.uid);
      } catch (e) {
        debugPrint('Error: $e');
      }
    }

    Map<String, dynamic>? productData;
    Map<String, dynamic>? postData;
    final urlRegExp = RegExp(r'(https?://[^\s]+)');
    final match = urlRegExp.firstMatch(text);

    if (match != null) {
      String url = match.group(0)!;
      if (url.contains('pang2chocolate.com/product/')) {
        productData = await _fetchProductFromUrl(url);
      } else if (url.contains('/comment') || url.contains('/post/')) {
        postData = await _fetchPostFromUrl(url);
      }
    }

    final batch = _firestore.batch();
    final commentRef =
        _firestore.collection('posts').doc(postId).collection('comments').doc();

    batch.set(
      commentRef,
      Comment(
        id: commentRef.id,
        userId: currentUser.uid,
        text: text,
        createdAt: FieldValue.serverTimestamp(),
        imageUrl: imageUrl,
        likes: 0,
        userImage: userData?.url,
        userName: userData?.name,
        likedBy: [],
        postData: postData,
        productData: productData != null ? Product.fromMap(productData) : null,
      ).toMap(),
    );

    final postRef = _firestore.collection('posts').doc(postId);
    batch.update(postRef, {'comments': FieldValue.increment(1)});

    try {
      await batch.commit();
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<Map<String, dynamic>?> _fetchProductFromUrl(String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      if (uri.pathSegments.length < 2) return null;

      String productId = uri.pathSegments[1];
      DocumentSnapshot doc =
          await _firestore.collection('products').doc(productId).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> _fetchPostFromUrl(String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      String? linkedPostId = uri.queryParameters['postId'];

      if (linkedPostId == null && uri.pathSegments.length >= 2) {
        linkedPostId = uri.pathSegments[1];
      }

      if (linkedPostId == null) return null;

      DocumentSnapshot doc =
          await _firestore.collection('posts').doc(linkedPostId).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    return null;
  }

  Future<void> togglePostLike(String postId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // We get the post from the current state (if loaded)
    final currentState = state.value;
    if (currentState == null) return;

    final postIndex = currentState.indexWhere((p) => p['postId'] == postId);
    if (postIndex == -1) return;

    final post = currentState[postIndex];
    List<String> likedBy = List<String>.from(post['likedBy'] ?? []);
    bool isLiked = likedBy.contains(currentUser.uid);

    // Optimistic Update
    final updatedLikedBy = List<String>.from(likedBy);
    if (isLiked) {
      updatedLikedBy.remove(currentUser.uid);
    } else {
      updatedLikedBy.add(currentUser.uid);
    }
    final updatedPost = Map<String, dynamic>.from(post);
    updatedPost['likedBy'] = updatedLikedBy;
    updatedPost['likes'] = (post['likes'] ?? 0) + (isLiked ? -1 : 1);

    final updatedState = List<Map<String, dynamic>>.from(currentState);
    updatedState[postIndex] = updatedPost;
    state = AsyncValue.data(updatedState);

    try {
      await _firestore.collection('posts').doc(postId).update({
        'likedBy':
            isLiked
                ? FieldValue.arrayRemove([currentUser.uid])
                : FieldValue.arrayUnion([currentUser.uid]),
        'likes': isLiked ? FieldValue.increment(-1) : FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> toggleCommentLike(String postId, String commentId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    if (!_comments.containsKey(postId)) return;

    final commentIndex = _comments[postId]!.indexWhere(
      (c) => c.id == commentId,
    );
    if (commentIndex == -1) return;

    final comment = _comments[postId]![commentIndex];
    List<String> likedBy = List<String>.from(comment.likedBy);
    bool isLiked = likedBy.contains(currentUser.uid);

    try {
      await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .update({
            'likedBy':
                isLiked
                    ? FieldValue.arrayRemove([currentUser.uid])
                    : FieldValue.arrayUnion([currentUser.uid]),
            'likes':
                isLiked ? FieldValue.increment(-1) : FieldValue.increment(1),
          });
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<MyUser> loadUser(String userId) async {
    if (_users.containsKey(userId)) {
      return _users[userId]!;
    }

    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userData = userDoc.data() ?? {};
    final user = MyUser.fromDocument(userData);

    _users[userId] = user;
    return user;
  }

  Future<void> preloadUsers() async {
    final currentState = state.value;
    if (currentState == null) return;

    final userIds =
        currentState.map((post) => post['userId'] as String).toSet().toList();
    for (final userId in userIds) {
      if (!_users.containsKey(userId)) {
        try {
          await loadUser(userId);
        } catch (e) {
          debugPrint('Error: $e');
        }
      }
    }
  }



  /// Submit a report (used by comment_item menu).
  Future<void> reportComment({
    required String reportedUserId,
    required String postId,
    String? commentId,
    String reason = 'Reported from comment',
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    await _repository.submitReport(
      reportedUserId: reportedUserId,
      reportingUserId: currentUser.uid,
      postId: postId,
      commentId: commentId,
      reason: reason,
    );
  }

  /// Load user categories for edit post dialog.
  Future<List<Map<String, String>>> loadUserCategories(String userId) =>
      _repository.getUserCategoriesList(userId);

  /// Stream comments for a post (used by guest_comments).
  Stream<QuerySnapshot> getCommentsStreamForPost(String postId) =>
      _repository.getCommentsStream(postId);

  /// Get a single post by ID (used by guest_comments post share tap).
  Future<List<Map<String, dynamic>>> getUserCategories() async {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId.isEmpty) return [];
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('categories')
          .orderBy('order', descending: false)
          .get();
      return snapshot.docs
          .map((doc) => {'id': doc.id, 'name': doc['name']})
          .toList();
    } catch (e) {
      debugPrint('Error loading categories: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getPostById(String postId) =>
      _repository.getPostById(postId);

  /// Stream multiple users by a list of their IDs (used by requests.dart).
  Stream<QuerySnapshot> getUsersByIdsStream(List<String> userIds) =>
      _repository.getUsersByIdsStream(userIds);
  Future<List<String>> getFollowingIds(String userId) async {
    final snapshot = await _firestore.collection('users').doc(userId).collection('following').get();
    return snapshot.docs.map((doc) => doc.id).toList();
  }

  Future<Set<String>> getFollowersIds(String userId) async {
    final snapshot = await _firestore.collection('users').doc(userId).collection('followers').get();
    return snapshot.docs.map((doc) => doc.id).toSet();
  }
}
