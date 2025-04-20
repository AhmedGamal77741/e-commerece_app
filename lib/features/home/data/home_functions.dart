import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
