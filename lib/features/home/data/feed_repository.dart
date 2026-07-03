import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:ecommerece_app/core/helpers/image_picker_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

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

  Stream<DocumentSnapshot> getCurrentUserStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  Stream<QuerySnapshot> getUsersChunkStream(List<String> userIds) {
    if (userIds.isEmpty) return const Stream.empty();
    return _firestore
        .collection('users')
        .where('userId', whereIn: userIds)
        .snapshots();
  }

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
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<Map<String, Map<String, dynamic>>> getAuthorsDataStreamRealtime(
    List<String> userIds,
  ) {
    userIds = userIds.where((id) => id.isNotEmpty).toList();
    if (userIds.isEmpty) return Stream.value({});

    final chunks = <List<String>>[];
    for (var i = 0; i < userIds.length; i += 10) {
      chunks.add(
        userIds.sublist(i, i + 10 > userIds.length ? userIds.length : i + 10),
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
    if (currentUserId.isEmpty || targetUserId.isEmpty) {
      return const Stream.empty();
    }
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
    if (currentUserId.isEmpty || targetUserId.isEmpty) {
      return const Stream.empty();
    }
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
    Map<String, double>? imageRatios,
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
        'imageRatios': imageRatios ?? {},
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

  String _lookupMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.gif':
        return 'image/gif';
      case '.heic':
      case '.heif':
        return 'image/heic';
      case '.jpeg':
      case '.jpg':
      default:
        return 'image/jpeg';
    }
  }

  Future<Map<String, dynamic>> _prepareUploadData({
    required XFile file,
    required String uid,
    int? index,
  }) async {
    final String originalName = file.name;
    final int dotIndex = originalName.lastIndexOf('.');
    final String baseName =
        dotIndex != -1 ? originalName.substring(0, dotIndex) : originalName;
    final String originalExtension =
        dotIndex != -1 ? originalName.substring(dotIndex).toLowerCase() : '';
    final String cleanedBaseName = baseName.replaceAll(
      RegExp(r'[^a-zA-Z0-9]'),
      '',
    );

    final Uint8List rawBytes = await file.readAsBytes();

    Uint8List uploadBytes;
    String finalExtension;
    String contentType;

    try {
      final Uint8List compressed = await FlutterImageCompress.compressWithList(
        rawBytes,
        minWidth: 1080,
        minHeight: 1080,
        quality: 82,
        format: CompressFormat.jpeg,
      );
      uploadBytes = compressed;
      finalExtension = '.jpg';
      contentType = 'image/jpeg';
    } catch (e) {
      uploadBytes = rawBytes;
      finalExtension = originalExtension;
      contentType = _lookupMimeType(originalExtension);
      if (originalExtension.toLowerCase() == '.heic' ||
          originalExtension.toLowerCase() == '.heif') {
        throw Exception('Failed to compress/convert HEIC image to JPEG: $e');
      }
    }

    final String timestamp = DateTime.now().microsecondsSinceEpoch.toString();
    final String indexSuffix = index != null ? '_$index' : '';
    final String fileName =
        '$timestamp${indexSuffix}_${uid}_$cleanedBaseName$finalExtension';

    return {
      'bytes': uploadBytes,
      'fileName': fileName,
      'metadata': SettableMetadata(contentType: contentType),
    };
  }

  /// Upload new images to Firebase Storage concurrently
  Future<List<String>> _uploadNewImages(List<XFile> files) async {
    if (files.isEmpty) return [];

    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) throw Exception("User not logged in");

    // Upload all images concurrently to speed up editing significantly
    final List<Future<String>> uploadTasks =
        files.asMap().entries.map((entry) async {
          try {
            final int index = entry.key;
            final XFile file = entry.value;

            final uploadData = await _prepareUploadData(
              file: file,
              uid: currentUserId,
              index: index,
            );

            final Reference storageRef = FirebaseStorage.instance
                .ref()
                .child('posts')
                .child(uploadData['fileName'] as String);

            final UploadTask uploadTask = storageRef.putData(
              uploadData['bytes'] as Uint8List,
              uploadData['metadata'] as SettableMetadata,
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

      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) throw Exception("User not logged in");

      // 2. Prepare upload data
      final uploadData = await _prepareUploadData(
        file: image,
        uid: currentUserId,
      );

      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('uploads')
          .child(uploadData['fileName'] as String);

      // 3. Upload to Firebase Storage
      final UploadTask uploadTask = storageRef.putData(
        uploadData['bytes'] as Uint8List,
        uploadData['metadata'] as SettableMetadata,
      );

      // 4. Get download URL when upload completes
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

      final currentUserId = _auth.currentUser?.uid ?? 'anonymous';

      List<String> downloadUrls = await Future.wait(
        images.asMap().entries.map((entry) async {
          final int index = entry.key;
          final XFile image = entry.value;

          final uploadData = await _prepareUploadData(
            file: image,
            uid: currentUserId,
            index: index,
          );

          final Reference storageRef = FirebaseStorage.instance
              .ref()
              .child('uploads')
              .child(uploadData['fileName'] as String);

          final UploadTask uploadTask = storageRef.putData(
            uploadData['bytes'] as Uint8List,
            uploadData['metadata'] as SettableMetadata,
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
      final currentUserId = _auth.currentUser?.uid ?? 'anonymous';

      final uploadData = await _prepareUploadData(
        file: image,
        uid: currentUserId,
        index: index,
      );

      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('uploads')
          .child(uploadData['fileName'] as String);

      final UploadTask uploadTask = storageRef.putData(
        uploadData['bytes'] as Uint8List,
        uploadData['metadata'] as SettableMetadata,
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

  Future<void> migrateHeicImagesToJpg() async {
    debugPrint("Starting HEIC to JPG migration...");
    try {
      final postsQuery = await _firestore.collection('posts').get();

      for (final doc in postsQuery.docs) {
        final data = doc.data();
        List<dynamic> imgUrls =
            data['imgUrls'] is List ? List.from(data['imgUrls']) : [];
        bool wasUpdated = false;

        for (int i = 0; i < imgUrls.length; i++) {
          final String url = imgUrls[i].toString();

          if (url.toLowerCase().contains('.heic') ||
              url.toLowerCase().contains('.heif')) {
            try {
              debugPrint("Found HEIC image in post ${doc.id}: $url");

              final response = await http.get(Uri.parse(url));
              if (response.statusCode != 200) {
                debugPrint("Failed to download image from $url");
                continue;
              }
              final Uint8List heicBytes = response.bodyBytes;

              debugPrint("Converting HEIC to JPEG...");
              final Uint8List jpgBytes =
                  await FlutterImageCompress.compressWithList(
                    heicBytes,
                    minWidth: 1080,
                    minHeight: 1080,
                    quality: 82,
                    format: CompressFormat.jpeg,
                  );

              final Reference oldRef = FirebaseStorage.instance.refFromURL(url);
              final String newPath = oldRef.fullPath.replaceAll(
                RegExp(r'\.heic|\.heif', caseSensitive: false),
                '.jpg',
              );
              final Reference newRef = FirebaseStorage.instance.ref().child(
                newPath,
              );

              debugPrint("Uploading JPEG version to $newPath...");
              final UploadTask uploadTask = newRef.putData(
                jpgBytes,
                SettableMetadata(contentType: 'image/jpeg'),
              );
              final TaskSnapshot snapshot = await uploadTask;
              final String newUrl = await snapshot.ref.getDownloadURL();

              imgUrls[i] = newUrl;
              wasUpdated = true;

              debugPrint("Deleting old HEIC image from storage...");
              await oldRef.delete();
            } catch (e) {
              debugPrint("Error migrating image $url: $e");
            }
          }
        }

        if (wasUpdated) {
          final Map<String, dynamic> updateData = {'imgUrls': imgUrls};
          if (imgUrls.isNotEmpty) {
            updateData['imgUrl'] = imgUrls[0];
          }
          await _firestore.collection('posts').doc(doc.id).update(updateData);
          debugPrint("Updated Firestore document: ${doc.id}");
        }
      }
      debugPrint("Migration completed successfully!");
    } catch (e) {
      debugPrint("Error running migration: $e");
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

  /// Submit a report to the 'reports' collection.
  Future<void> submitReport({
    required String reportedUserId,
    required String reportingUserId,
    required String postId,
    String? commentId,
    String reason = 'Reported from comment',
  }) async {
    await _firestore.collection('reports').add({
      'reportedUserId': reportedUserId,
      'reportingUserId': reportingUserId,
      'postId': postId,
      if (commentId != null) 'commentId': commentId,
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Get a user's categories as a simple list.
  Future<List<Map<String, String>>> getUserCategoriesList(String userId) async {
    final snapshot =
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('categories')
            .orderBy('order', descending: false)
            .get();
    return snapshot.docs
        .map(
          (doc) => <String, String>{
            'id': doc.id,
            'name': doc['name'] as String,
          },
        )
        .toList();
  }

  /// Stream a single user document.
  Stream<DocumentSnapshot> getUserDocStream(String userId) {
    return _firestore.collection('users').doc(userId).snapshots();
  }

  /// Stream users by a list of IDs (Firestore whereIn limit: 30).
  Stream<QuerySnapshot> getUsersByIdsStream(List<String> userIds) {
    if (userIds.isEmpty) {
      return Stream.value(
        _firestore.collection('__empty__').snapshots() as QuerySnapshot,
      );
    }
    return _firestore
        .collection('users')
        .where(FieldPath.documentId, whereIn: userIds)
        .snapshots();
  }

  /// Stream comments for a post.
  Stream<QuerySnapshot> getCommentsStream(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Get a single post document by ID.
  Future<Map<String, dynamic>?> getPostById(String postId) async {
    final doc = await _firestore.collection('posts').doc(postId).get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>;
    data['postId'] = doc.id;
    return data;
  }
}
