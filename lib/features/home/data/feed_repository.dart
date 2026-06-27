import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:ecommerece_app/core/helpers/image_picker_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

class FeedRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FeedRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _firestore = firestore,
       _auth = auth;

  Stream<QuerySnapshot> getUserCategoriesStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('categories')
        .orderBy('order')
        .snapshots();
  }

  Stream<QuerySnapshot> getUserPostsStream(
    String userId, {
    String? categoryId,
  }) {
    Query query = _firestore
        .collection('posts')
        .where('userId', isEqualTo: userId);

    if (categoryId != null) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }

    return query.orderBy('createdAt', descending: true).snapshots();
  }

  Stream<DocumentSnapshot> getUserStream(String userId) {
    return _firestore.collection('users').doc(userId).snapshots();
  }

  Stream<QuerySnapshot> getNotificationsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getUnreadNotificationsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .limit(1)
        .snapshots();
  }

  Stream<QuerySnapshot> getHiddenFriendsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('hiddenFriends')
        .snapshots();
  }

  Stream<QuerySnapshot> searchUsersStream() {
    return _firestore.collection('users').snapshots();
  }

  Stream<QuerySnapshot> searchPostsStream() {
    return _firestore.collection('posts').snapshots();
  }

  Stream<Map<String, Map<String, dynamic>>> getAuthorsDataStreamRealtime(
    List<String> authorIds,
  ) {
    if (authorIds.isEmpty) return Stream.value({});

    final chunks = <List<String>>[];
    for (var i = 0; i < authorIds.length; i += 10) {
      chunks.add(
        authorIds.sublist(
          i,
          i + 10 > authorIds.length ? authorIds.length : i + 10,
        ),
      );
    }

    final streams =
        chunks.map((chunk) {
          return _firestore
              .collection('users')
              .where(FieldPath.documentId, whereIn: chunk)
              .snapshots()
              .map((snapshot) {
                final map = <String, Map<String, dynamic>>{};
                for (var doc in snapshot.docs) {
                  map[doc.id] = doc.data();
                }
                return map;
              });
        }).toList();

    if (streams.length == 1) return streams[0];

    return Stream.multi((controller) {
      final dataMaps = List<Map<String, Map<String, dynamic>>>.filled(
        streams.length,
        {},
      );
      final subscriptions = <StreamSubscription>[];

      for (var i = 0; i < streams.length; i++) {
        final sub = streams[i].listen(
          (dataMap) {
            dataMaps[i] = dataMap;
            final combinedMap = <String, Map<String, dynamic>>{};
            for (var map in dataMaps) {
              combinedMap.addAll(map);
            }
            controller.add(combinedMap);
          },
          onError: (e) {
            controller.addError(e);
          },
        );
        subscriptions.add(sub);
      }

      controller.onCancel = () {
        for (var sub in subscriptions) {
          sub.cancel();
        }
      };
    });
  }

  Future<void> sendFollowRequest(String targetUserId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;
    await _firestore
        .collection('users')
        .doc(targetUserId)
        .collection('followRequests')
        .doc(currentUserId)
        .set({
          'userId': currentUserId,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> cancelFollowRequest(String targetUserId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;
    await _firestore
        .collection('users')
        .doc(targetUserId)
        .collection('followRequests')
        .doc(currentUserId)
        .delete();
  }

  Stream<QuerySnapshot> getFollowRequestsStream(String targetUserId) {
    return _firestore
        .collection('users')
        .doc(targetUserId)
        .collection('followRequests')
        .snapshots();
  }

  Stream<QuerySnapshot> getFollowingStreamForUser(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('following')
        .snapshots();
  }

  Stream<DocumentSnapshot> getFollowingDocStream(
    String currentUserId,
    String targetUserId,
  ) {
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .doc(targetUserId)
        .snapshots();
  }

  Stream<DocumentSnapshot> getFollowRequestDocStream(
    String targetUserId,
    String currentUserId,
  ) {
    return _firestore
        .collection('users')
        .doc(targetUserId)
        .collection('followRequests')
        .doc(currentUserId)
        .snapshots();
  }

  Future<void> markAllNotificationsAsRead() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    final notificationsRef = _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('notifications');
    final unread =
        await notificationsRef.where('isRead', isEqualTo: false).get();

    final batch = _firestore.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<MyUser> getUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return MyUser.fromDocument(doc.data()!);
      }
      return MyUser.empty;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markPostNotInterested({required String postId}) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception("User not logged in");

      final postRef = _firestore.collection('posts').doc(postId);

      // Add the current user's ID to the notInterestedBy array
      // If the user ID is already in the array, it won't be added again
      await postRef.update({
        'notInterestedBy': FieldValue.arrayUnion([currentUser.uid]),
      });
    } catch (e) {
      rethrow; // Re-throw to handle in UI
    }
  }

  Future<void> blockUser({required String userIdToBlock}) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception("User not logged in");

      // Reference to the current user's document
      final userRef = _firestore.collection('users').doc(currentUser.uid);

      final blocksCollection = _firestore.collection('blocks');
      final newBlockRef = blocksCollection.doc();

      final batch = _firestore.batch();

      batch.update(userRef, {
        'blocked': FieldValue.arrayUnion([userIdToBlock]),
      });

      batch.set(newBlockRef, {
        'blockedUserId': userIdToBlock,
        'blockedBy': currentUser.uid,
        'blockId': newBlockRef.id,
      });

      // Check if the user to block actually exists (prevents not-found errors if they deleted their account)
      final blockedUserRef = _firestore.collection('users').doc(userIdToBlock);
      final blockedUserDoc = await blockedUserRef.get();
      final bool blockedUserExists = blockedUserDoc.exists;

      // Check follow relationships to decrement counts
      final followingRef1 = _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('following')
          .doc(userIdToBlock);
      final followerRef1 = _firestore
          .collection('users')
          .doc(userIdToBlock)
          .collection('followers')
          .doc(currentUser.uid);
      final followingDoc1 = await followingRef1.get();
      if (followingDoc1.exists) {
        batch.delete(followingRef1);
        batch.delete(followerRef1);
        batch.update(userRef, {'followingCount': FieldValue.increment(-1)});
        if (blockedUserExists) {
          batch.update(blockedUserRef, {
            'followerCount': FieldValue.increment(-1),
          });
        }
      }

      final followingRef2 = _firestore
          .collection('users')
          .doc(userIdToBlock)
          .collection('following')
          .doc(currentUser.uid);
      final followerRef2 = _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('followers')
          .doc(userIdToBlock);
      final followingDoc2 = await followingRef2.get();
      if (followingDoc2.exists) {
        batch.delete(followingRef2);
        batch.delete(followerRef2);
        if (blockedUserExists) {
          batch.update(blockedUserRef, {
            'followingCount': FieldValue.increment(-1),
          });
        }
        batch.update(userRef, {'followerCount': FieldValue.increment(-1)});
      }

      // Delete the direct chat room between the users if it exists
      final participants = [currentUser.uid, userIdToBlock]..sort();
      final chatRoomId = participants.join('_');
      final chatDoc =
          await _firestore.collection('chatRooms').doc(chatRoomId).get();
      if (chatDoc.exists) {
        batch.delete(chatDoc.reference);
      }

      // Remove from each other's friends array
      batch.update(userRef, {
        'friends': FieldValue.arrayRemove([userIdToBlock]),
      });
      if (blockedUserExists) {
        batch.update(blockedUserRef, {
          'friends': FieldValue.arrayRemove([currentUser.uid]),
        });
      }

      await batch.commit();
    } catch (e) {
      rethrow; // Re-throw to handle in UI
    }
  }

  Future<void> unblockUser({required String userIdToUnblock}) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception("User not logged in");

      final userRef = _firestore.collection('users').doc(currentUser.uid);

      final batch = _firestore.batch();

      batch.update(userRef, {
        'blocked': FieldValue.arrayRemove([userIdToUnblock]),
      });

      final blocksQuery =
          await _firestore
              .collection('blocks')
              .where('blockedBy', isEqualTo: currentUser.uid)
              .where('blockedUserId', isEqualTo: userIdToUnblock)
              .get();

      for (final doc in blocksQuery.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> reportUser({
    required String reportedUserId,
    required String postId,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception("User not logged in");

      final reportsCollection = _firestore.collection('reports');

      final newReportRef = reportsCollection.doc();

      await newReportRef.set({
        'reportedUserId': reportedUserId,
        'reportingUserId': currentUser.uid,
        'reportId': newReportRef.id,
        'postId': postId,
        /*       'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'resolved': false,  */
      });
    } catch (e) {
      rethrow; // Re-throw to handle in UI
    }
  }

  Future<void> uploadPost({
    required String text,
    required List<String> imgUrls,
    String? categoryId,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception("User not logged in");

      final postsCollection = _firestore.collection('posts');
      final newPostRef = postsCollection.doc();
      final batch = _firestore.batch();

      batch.set(newPostRef, {
        'userId': currentUser.uid,
        'postId': newPostRef.id,
        'text': text,
        'imgUrl': imgUrls.isNotEmpty ? imgUrls[0] : null,
        'imgUrls': imgUrls,
        'categoryId': categoryId,
        'likes': 0,
        'comments': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'likedBy': [],
        'notInterestedBy': [],
      });

      batch.update(_firestore.collection('users').doc(currentUser.uid), {
        'lastPostCreatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      rethrow; // Re-throw to handle in UI
    }
  }

  Future<void> deletePost({required String postId}) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception("User not logged in");
      
      final postDoc = await _firestore.collection('posts').doc(postId).get();
      if (!postDoc.exists) return;
      
      if (postDoc.data()?['userId'] != currentUser.uid) {
        throw Exception("You don't have permission to delete this post.");
      }

      await _firestore.collection('posts').doc(postId).delete();
    } catch (e) {
      rethrow;
    }
  }

  /// Upload new images to Firebase Storage concurrently
  Future<List<String>> _uploadNewImages(List<XFile> files) async {
    if (files.isEmpty) return [];

    // Upload all images concurrently to speed up editing significantly
    final List<Future<String>> uploadTasks =
        files.map((file) async {
          try {
            final String fileName =
                '${DateTime.now().millisecondsSinceEpoch}_${_auth.currentUser!.uid}_${file.name.replaceAll(RegExp(r'[^a-zA-Z0-9.]'), '')}.jpg';
            final Reference storageRef = FirebaseStorage.instance
                .ref()
                .child('posts')
                .child(fileName);

            final Uint8List rawBytes = await file.readAsBytes();

            // Compress on both mobile and web using flutter_image_compress (WASM on web)
            Uint8List uploadBytes;
            try {
              final Uint8List compressed =
                  await FlutterImageCompress.compressWithList(
                    rawBytes,
                    minWidth: 1080,
                    minHeight: 1080,
                    quality: 82,
                    format: CompressFormat.jpeg,
                  );
              uploadBytes = compressed;
            } catch (e) {
              uploadBytes = rawBytes;
            }

            final UploadTask uploadTask = storageRef.putData(
              uploadBytes,
              SettableMetadata(contentType: 'image/jpeg'),
            );

            final TaskSnapshot snapshot = await uploadTask;
            return await snapshot.ref.getDownloadURL();
          } catch (e) {
            throw Exception('Failed to upload image during edit: $e');
          }
        }).toList();

    return await Future.wait(uploadTasks);
  }

  /// Update a post with new text and images
  Future<void> updatePost({
    required String postId,
    required String text,
    required List<String> networkImgUrls, // Existing URLs to keep
    required List<XFile> newImages, // New images to upload
    String? categoryId,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception("User not logged in");

      // Upload new images first
      final List<String> uploadedUrls = await _uploadNewImages(newImages);

      // Combine network URLs with newly uploaded URLs
      final List<String> allImgUrls = [...networkImgUrls, ...uploadedUrls];

      // Update the post in Firestore
      await _firestore.collection('posts').doc(postId).update({
        'text': text,
        'imgUrls': allImgUrls,
        'imgUrl':
            allImgUrls.isNotEmpty
                ? allImgUrls[0]
                : null, // Keep for backward compatibility
        'categoryId': categoryId,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<String> uploadImageToFirebaseStorageHome() async {
    try {
      // 1. Pick image from gallery
      final XFile? image = await ImagePickerHelper.pickImage();
      if (image == null) return "";

      // 2. Prepare storage reference with unique filename
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}${_auth.currentUser!.uid}.jpg';
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('uploads')
          .child(fileName);

      // 3. Read image bytes (works for both mobile and web)
      final bytes = await image.readAsBytes();

      // 4. Upload to Firebase Storage
      final UploadTask uploadTask = storageRef.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'), // Set MIME type
      );

      // 5. Get download URL when upload completes
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<List<String>> uploadMultipleImagesToFirebaseHome() async {
    try {
      final List<XFile> images = await ImagePickerHelper.pickMultiImage();
      if (images.isEmpty) return [];

      List<String> downloadUrls = await Future.wait(
        images.map((image) async {
          final String timestamp =
              DateTime.now().millisecondsSinceEpoch.toString();
          final String uid = _auth.currentUser?.uid ?? 'anonymous';
          final int index = images.indexOf(image);
          final String fileName = '${timestamp}_${index}_$uid.jpg';

          final Uint8List rawBytes = await image.readAsBytes();

          // Compress on both mobile and web using flutter_image_compress (WASM on web)
          Uint8List uploadBytes;
          try {
            final Uint8List compressed =
                await FlutterImageCompress.compressWithList(
                  rawBytes,
                  minWidth: 1080,
                  minHeight: 1080,
                  quality: 82,
                  format: CompressFormat.jpeg,
                );
            // Fall back to raw bytes if compression somehow returns null
            uploadBytes = compressed;
          } catch (e) {
            uploadBytes = rawBytes;
          }

          final Reference storageRef = FirebaseStorage.instance
              .ref()
              .child('uploads')
              .child(fileName);

          final UploadTask uploadTask = storageRef.putData(
            uploadBytes,
            SettableMetadata(contentType: 'image/jpeg'),
          );

          final TaskSnapshot snapshot = await uploadTask;
          return await snapshot.ref.getDownloadURL();
        }),
      );

      return downloadUrls;
    } catch (e) {
      throw Exception('Failed to upload images: $e');
    }
  }

  Future<String> uploadSingleImageToFirebase(
    XFile image,
    int index, {
    Function(double)? onProgress,
  }) async {
    try {
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String uid = _auth.currentUser?.uid ?? 'anonymous';
      final String fileName = '${timestamp}_${index}_$uid.jpg';

      final Uint8List rawBytes = await image.readAsBytes();

      // Compress on both mobile and web using flutter_image_compress (WASM on web)
      Uint8List uploadBytes;
      try {
        final Uint8List compressed =
            await FlutterImageCompress.compressWithList(
              rawBytes,
              minWidth: 1080,
              minHeight: 1080,
              quality: 82,
              format: CompressFormat.jpeg,
            );
        // Fall back to raw bytes if compression somehow returns null
        uploadBytes = compressed;
      } catch (e) {
        uploadBytes = rawBytes;
      }

      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('uploads')
          .child(fileName);

      final UploadTask uploadTask = storageRef.putData(
        uploadBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          if (snapshot.totalBytes > 0) {
            final double progress =
                snapshot.bytesTransferred / snapshot.totalBytes;
            onProgress(progress);
          }
        });
      }

      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload single image: $e');
    }
  }

  Future<void> migrateLastPostCreatedAt() async {
    try {
      final postsSnapshot = await _firestore.collection('posts').get();

      // Map to keep track of the latest post timestamp for each user
      final Map<String, DateTime> latestPosts = {};

      for (var doc in postsSnapshot.docs) {
        final data = doc.data();
        final userId = data['userId'] as String?;
        final createdAtRaw = data['createdAt'];

        if (userId == null || createdAtRaw == null) continue;

        DateTime? postDate;
        if (createdAtRaw is Timestamp) {
          postDate = createdAtRaw.toDate();
        } else if (createdAtRaw is int) {
          postDate = DateTime.fromMillisecondsSinceEpoch(createdAtRaw);
        }

        if (postDate != null) {
          final currentLatest = latestPosts[userId];
          if (currentLatest == null || postDate.isAfter(currentLatest)) {
            latestPosts[userId] = postDate;
          }
        }
      }

      // Update each user's profile if their post timestamp is newer than their current one
      for (var entry in latestPosts.entries) {
        final userId = entry.key;
        final latestPostDate = entry.value;

        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          final currentLastPostRaw = userData?['lastPostCreatedAt'];
          DateTime? currentLastPost;

          if (currentLastPostRaw is Timestamp) {
            currentLastPost = currentLastPostRaw.toDate();
          } else if (currentLastPostRaw is int) {
            currentLastPost = DateTime.fromMillisecondsSinceEpoch(
              currentLastPostRaw,
            );
          }

          if (currentLastPost == null ||
              latestPostDate.isAfter(currentLastPost)) {
            await _firestore.collection('users').doc(userId).update({
              'lastPostCreatedAt': Timestamp.fromDate(latestPostDate),
            });
          }
        }
      }
    } catch (e) {
      rethrow;
    }
  }
}
