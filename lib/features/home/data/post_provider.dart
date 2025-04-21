import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_entity.dart';
import 'package:ecommerece_app/features/home/models/comment_model.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostsProvider extends ChangeNotifier {
  final Map<String, Map<String, dynamic>> _posts = {};
  final Map<String, List<Comment>> _comments = {};
  final Map<String, MyUserEntity> _users = {};
  final Set<String> _changedPostIds = {};
  final Set<String> _loadingCommentPosts = {};

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isListening = false;

  // Getters
  Map<String, Map<String, dynamic>> get posts => _posts;
  List<String> get postIds => _posts.keys.toList();
  Map<String, dynamic>? getPost(String postId) => _posts[postId];
  List<Comment> getComments(String postId) => _comments[postId] ?? [];
  bool isLoadingComments(String postId) =>
      _loadingCommentPosts.contains(postId);
  MyUserEntity? getUser(String userId) => _users[userId];
  bool hasPostChanged(String postId) => _changedPostIds.contains(postId);

  // Start listening to posts
  void startListening() {
    if (_isListening) return;

    _isListening = true;
    _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            final String postId = change.doc.id;
            _posts[postId] = change.doc.data()!;
            _changedPostIds.add(postId);

            // If we're already loading comments for this post, refresh them
            if (_comments.containsKey(postId)) {
              loadComments(postId);
            }
          }
          notifyListeners();
          _changedPostIds.clear();
        });
  }

  // Load comments for a specific post
  Future<void> loadComments(String postId) async {
    if (_loadingCommentPosts.contains(postId)) return;

    _loadingCommentPosts.add(postId);
    notifyListeners();

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

      // Preload user data for comment authors
      final userIds =
          comments.map((comment) => comment.userId).toSet().toList();

      for (final userId in userIds) {
        if (!_users.containsKey(userId)) {
          try {
            await loadUser(userId);
          } catch (e) {
            print('Error loading user $userId: $e');
          }
        }
      }
    } catch (e) {
      print('Error loading comments for post $postId: $e');
    } finally {
      _loadingCommentPosts.remove(postId);
      notifyListeners();
    }
  }

  // Listen to comments for a specific post in real-time
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

          // Preload user data for new comment authors
          for (final comment in comments) {
            if (!_users.containsKey(comment.userId)) {
              loadUser(comment.userId);
            }
          }

          notifyListeners();
        });
  }

  // Add a comment to a post
  Future<void> addComment(String postId, String text) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Get current user data
    MyUserEntity? userData = _users[currentUser.uid];

    if (userData == null) {
      try {
        userData = await loadUser(currentUser.uid);
      } catch (e) {
        print('Error loading user data: $e');
        // Continue with basic user data from Firebase Auth
      }
    }

    // Create a batch for atomic operations
    final batch = _firestore.batch();

    // Create comment document reference
    final commentRef =
        _firestore.collection('posts').doc(postId).collection('comments').doc();

    // Set comment data
    batch.set(commentRef, {
      'userId': currentUser.uid,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'likes': 0,
      'userImage': userData?.url ?? currentUser.photoURL,
      'userName': userData?.name ?? currentUser.displayName,
      'likedBy': [], // Initialize empty likedBy array
    });

    // Update post comment count
    final postRef = _firestore.collection('posts').doc(postId);
    batch.update(postRef, {'comments': FieldValue.increment(1)});

    // Commit the batch
    try {
      await batch.commit();

      // Optimistically update local state
      if (_posts.containsKey(postId)) {
        _posts[postId]!['comments'] = (_posts[postId]!['comments'] ?? 0) + 1;
      }

      // If we're tracking comments for this post, add the new comment
      if (_comments.containsKey(postId)) {
        final newComment = Comment(
          id: commentRef.id,
          userId: currentUser.uid,
          text: text,
          createdAt: Timestamp.now(),
          likes: 0,
          userImage: userData?.url ?? currentUser.photoURL,
          userName: userData?.name ?? currentUser.displayName,
          likedBy: [], // Initialize empty likedBy array
        );

        _comments[postId] = [newComment, ..._comments[postId]!];
      }

      notifyListeners();
    } catch (e) {
      print('Error adding comment: $e');
      throw e;
    }
  }

  // Toggle like on a post
  Future<void> togglePostLike(String postId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Get the current post data
    final post = _posts[postId];
    if (post == null) return;

    // Check if already liked
    List<String> likedBy = List<String>.from(post['likedBy'] ?? []);
    bool isLiked = likedBy.contains(currentUser.uid);

    // Update locally first (optimistic)
    if (isLiked) {
      likedBy.remove(currentUser.uid);
      post['likes'] = (post['likes'] ?? 1) - 1;
    } else {
      likedBy.add(currentUser.uid);
      post['likes'] = (post['likes'] ?? 0) + 1;
    }
    post['likedBy'] = likedBy;

    // Mark this post as changed
    _changedPostIds.add(postId);

    // Notify UI to update
    notifyListeners();
    _changedPostIds.clear();

    // Update in Firestore
    try {
      await _firestore.collection('posts').doc(postId).update({
        'likedBy':
            isLiked
                ? FieldValue.arrayRemove([currentUser.uid])
                : FieldValue.arrayUnion([currentUser.uid]),
        'likes': isLiked ? FieldValue.increment(-1) : FieldValue.increment(1),
      });
    } catch (e) {
      // If update fails, revert the local change
      print('Error updating like: $e');
      if (isLiked) {
        likedBy.add(currentUser.uid);
        post['likes'] = (post['likes'] ?? 0) + 1;
      } else {
        likedBy.remove(currentUser.uid);
        post['likes'] = (post['likes'] ?? 1) - 1;
      }
      post['likedBy'] = likedBy;

      _changedPostIds.add(postId);
      notifyListeners();
      _changedPostIds.clear();
    }
  }

  Future<void> toggleCommentLike(String postId, String commentId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Find the comment in our local state
    if (!_comments.containsKey(postId)) return;

    final commentIndex = _comments[postId]!.indexWhere(
      (c) => c.id == commentId,
    );
    if (commentIndex == -1) return;

    final comment = _comments[postId]![commentIndex];

    // Check if already liked
    List<String> likedBy = List<String>.from(comment.likedBy ?? []);
    bool isLiked = likedBy.contains(currentUser.uid);

    // Create a new comment object with updated like data (immutable approach)
    final updatedComment = Comment(
      id: comment.id,
      userId: comment.userId,
      text: comment.text,
      createdAt: comment.createdAt,
      likes: isLiked ? (comment.likes - 1) : (comment.likes + 1),
      userImage: comment.userImage,
      userName: comment.userName,
      likedBy:
          isLiked
              ? likedBy.where((id) => id != currentUser.uid).toList()
              : [...likedBy, currentUser.uid],
    );

    // Update the comment in our local state
    final updatedComments = List<Comment>.from(_comments[postId]!);
    updatedComments[commentIndex] = updatedComment;
    _comments[postId] = updatedComments;

    // Notify UI to update
    notifyListeners();

    // Update in Firestore
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
      // If update fails, revert the local change
      print('Error updating comment like: $e');

      // Revert to the original comment
      final revertedComments = List<Comment>.from(_comments[postId]!);
      revertedComments[commentIndex] = comment;
      _comments[postId] = revertedComments;

      notifyListeners();
    }
  }

  // Load a user if not already loaded
  Future<MyUserEntity> loadUser(String userId) async {
    if (_users.containsKey(userId)) {
      return _users[userId]!;
    }

    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userData = userDoc.data() ?? {};

    final user = MyUserEntity(
      userId: userId,
      name: userData['name'] ?? 'Unknown User',
      url: userData['url'] ?? 'https://via.placeholder.com/150',
      email: userData['email'],
      // Add other fields as needed
    );

    _users[userId] = user;
    notifyListeners();
    return user;
  }

  // Preload users for all posts
  Future<void> preloadUsers() async {
    final userIds =
        _posts.values.map((post) => post['userId'] as String).toSet().toList();

    for (final userId in userIds) {
      if (!_users.containsKey(userId)) {
        try {
          await loadUser(userId);
        } catch (e) {
          print('Error loading user $userId: $e');
        }
      }
    }
  }
}
