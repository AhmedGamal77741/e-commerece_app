import 'dart:convert';
import 'dart:io';
import 'package:ecommerece_app/features/auth/signup/data/models/user_entity.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

Future<MyUserEntity> getUser(String userId) async {
  try {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      return MyUserEntity.fromDocument(doc.data()!);
    }
    return MyUserEntity(userId: "", email: "", name: "", url: "");
  } catch (e) {
    print('Error fetching user: $e');
    throw e;
  }
}

Future<void> addComment(String postId, String text) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return;

  // Get user data
  final userDoc =
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

  final userData = userDoc.data() ?? {};

  // Create comment
  final commentRef =
      FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc();

  // Update comment count in post
  final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);

  // Use a batch to ensure both operations succeed or fail together
  final batch = FirebaseFirestore.instance.batch();

  batch.set(commentRef, {
    'userId': currentUser.uid,
    'text': text,
    'createdAt': FieldValue.serverTimestamp(),
    'likes': 0,
    'userImage': userData['url'] ?? currentUser.photoURL,
    'userName': userData['name'] ?? currentUser.displayName,
  });

  batch.update(postRef, {'comments': FieldValue.increment(1)});

  await batch.commit();
}

Future<void> markPostNotInterested({required String postId}) async {
  try {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception("User not logged in");

    final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);

    // Add the current user's ID to the notInterestedBy array
    // If the user ID is already in the array, it won't be added again
    await postRef.update({
      'notInterestedBy': FieldValue.arrayUnion([currentUser.uid]),
    });

    print('Post marked as not interested successfully!');
  } catch (e) {
    print('Error marking post as not interested: $e');
    throw e; // Re-throw to handle in UI
  }
}

Future<void> blockUser({required String userIdToBlock}) async {
  try {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception("User not logged in");

    // Reference to the current user's document
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid);

    // Use arrayUnion to add the user ID to the blocked array
    // This operation is atomic and won't add duplicates
    await userRef.update({
      'blocked': FieldValue.arrayUnion([userIdToBlock]),
    });

    print('User blocked successfully!');
  } catch (e) {
    print('Error blocking user: $e');
    throw e; // Re-throw to handle in UI
  }
}

Future<void> reportUser({required String reportedUserId}) async {
  try {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception("User not logged in");

    final reportsCollection = FirebaseFirestore.instance.collection('reports');

    // Create a new document with auto-generated ID
    final newReportRef = reportsCollection.doc();

    await newReportRef.set({
      'reportedUserId': reportedUserId,
      'reportingUserId': currentUser.uid,
      'reportId': newReportRef.id,
      /*       'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
      'resolved': false,  */
    });

    print('User reported successfully!');
  } catch (e) {
    print('Error reporting user: $e');
    throw e; // Re-throw to handle in UI
  }
}

Future<void> uploadPost({required String text, required String imgUrl}) async {
  try {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception("User not logged in");

    final postsCollection = FirebaseFirestore.instance.collection('posts');

    // Create a new document with auto-generated ID
    final newPostRef = postsCollection.doc();

    await newPostRef.set({
      'userId': currentUser.uid,
      'postId': newPostRef.id,
      'text': text,
      'imgUrl': imgUrl,
      'likes': 0,
      'comments': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'likedBy': [],
      'notInterestedBy': [],
    });

    print('Post uploaded successfully!');
  } catch (e) {
    print('Error uploading post: $e');
    throw e; // Re-throw to handle in UI
  }
}

Future<String> uploadImageToImgBB() async {
  final XFile? image = await ImagePicker().pickImage(
    source: ImageSource.gallery,
  );
  if (image == null) return "";

  final bytes = await File(image.path).readAsBytes();
  final base64Image = base64Encode(bytes);

  final response = await http.post(
    Uri.parse('https://api.imgbb.com/1/upload'),
    body: {'key': 'df668aeecb751b64bc588772056a32df', 'image': base64Image},
  );

  if (response.statusCode == 200) {
    final jsonData = jsonDecode(response.body);
    return jsonData['data']['url'];
  } else {
    throw Exception('Failed to upload: ${response.body}');
  }
}
