import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerece_app/features/home/domain/feed_controller.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';

class CommentsState {
  final Map<String, dynamic>? postData;
  final MyUser? postAuthor;
  final bool isNormalUser;

  CommentsState({
    this.postData,
    this.postAuthor,
    this.isNormalUser = true,
  });
}

class CommentsNotifier extends AsyncNotifier<CommentsState> {
  final String postId;
  CommentsNotifier(this.postId);

  @override
  FutureOr<CommentsState> build() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    bool isNormalUser = true;

    if (currentUser != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      final userData = userDoc.data();
      isNormalUser = userData == null || (userData['type'] == 'user' && userData['isSub'] != true);
    }

    Map<String, dynamic>? postData;
    final feedState = ref.read(feedControllerProvider).value;
    if (feedState != null) {
      for (var p in feedState) {
        if (p['postId'] == postId || p['id'] == postId) {
          postData = p;
          break;
        }
      }
    }

    if (postData == null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('posts').doc(postId).get();
        if (doc.exists) {
          postData = doc.data();
          if (postData != null) {
            postData['postId'] = postId;
          }
        }
      } catch (e) {
        debugPrint('Error: $e');
      }
    }

    MyUser? postAuthor;
    if (postData != null && postData['userId'] != null) {
      try {
        postAuthor = await ref.read(feedControllerProvider.notifier).loadUser(postData['userId']);
      } catch (e) {
        debugPrint('Error: $e');
      }
    }

    ref.read(feedControllerProvider.notifier).listenToComments(postId);

    return CommentsState(
      postData: postData,
      postAuthor: postAuthor,
      isNormalUser: isNormalUser,
    );
  }

  Future<void> submitComment(String text, {File? imageFile, Uint8List? imageBytes}) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (currentUserId.isEmpty) return;
    
    String? imageUrl;
    if (imageFile != null || imageBytes != null) {
      try {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$currentUserId.jpg';
        final storageRef = FirebaseStorage.instance.ref().child('chat_images/$fileName');
        UploadTask task;
        if (kIsWeb && imageBytes != null) {
          task = storageRef.putData(imageBytes, SettableMetadata(contentType: 'image/jpeg'));
        } else if (imageFile != null) {
          task = storageRef.putFile(imageFile);
        } else {
          throw Exception("No valid image data");
        }
        imageUrl = await (await task).ref.getDownloadURL();
      } catch (e) {
        debugPrint('Error: $e');
      }
    }

    try {
      await ref.read(feedControllerProvider.notifier).addComment(postId, text, imageUrl: imageUrl);
    } catch (e) {
      rethrow;
    }
  }
}

final commentsNotifierProvider = AsyncNotifierProvider.family<CommentsNotifier, CommentsState, String>(CommentsNotifier.new);
