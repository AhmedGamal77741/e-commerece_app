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
    StreamProvider.family<Map<String, Map<String, dynamic>>, List<String>>((
      ref,
      authorIds,
    ) {
      return ref
          .watch(feedRepositoryProvider)
          .getAuthorsDataStreamRealtime(authorIds);
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

  @override
  FutureOr<List<Map<String, dynamic>>> build() async {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;

    final postsDocs = await ref.watch(allPostsStreamProvider.future);

    final authorIds = <String>{};
    for (var doc in postsDocs) {
      final data = doc.data() as Map<String, dynamic>;
      authorIds.add(data['userId'] as String);
    }

    // Sort author IDs so the parameter remains consistent for caching
    final sortedAuthorIds = authorIds.toList()..sort();
    final authorsMap = await ref.watch(
      authorsDataMapProvider(sortedAuthorIds).future,
    );

    if (user == null) {
      // Guest feed
      return postsDocs
          .where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final authorData = authorsMap[data['userId'] as String] ?? {};
            return (authorData['isPrivate'] ?? false) == false;
          })
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['postId'] = data['postId'] ?? doc.id;
            return data;
          })
          .toList();
    }

    // Authenticated user feed
    final userDoc = await ref.watch(userProfileDocProvider(user.uid).future);
    final userData = userDoc?.data() as Map<String, dynamic>?;
    if (userData == null) return [];

    final blockedUsers = List<String>.from(userData['blocked'] ?? []);
    final isSub = userData['isSub'] ?? false;

    final hiddenFriends = await ref.watch(
      hiddenFriendsListProvider(user.uid).future,
    );

    Set<String> followingSet = {};
    if (isSub) {
      followingSet = await ref.watch(followingSetProvider(user.uid).future);
    }

    return postsDocs
        .where((doc) {
          final data = doc.data() as Map<String, dynamic>;
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
          final data = doc.data() as Map<String, dynamic>;
          data['postId'] = data['postId'] ?? doc.id;
          return data;
        })
        .toList();
  }

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
}
