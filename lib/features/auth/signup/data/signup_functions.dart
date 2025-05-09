import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_entity.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:rxdart/rxdart.dart';

Future<String> uploadImageToImgBB() async {
  final XFile? image = await ImagePicker().pickImage(
    source: ImageSource.gallery,
  );
  if (image == null) return "";

  Uint8List bytes;
  if (kIsWeb) {
    // On web, use image.readAsBytes() directly
    bytes = await image.readAsBytes();
  } else {
    // On mobile, File is available
    bytes = await image.readAsBytes(); // no need for dart:io File
  }

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

class FirebaseUserRepo {
  final FirebaseAuth _firebaseAuth;

  final usersCollection = FirebaseFirestore.instance.collection('users');

  FirebaseUserRepo({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  Stream<MyUser?> get user {
    return _firebaseAuth.authStateChanges().asyncExpand((firebaseUser) async* {
      print('⚡ authStateChanges fired: $firebaseUser');
      if (firebaseUser == null) {
        // No Firebase user → unauthenticated
        yield null;
      } else {
        final docRef = usersCollection.doc(firebaseUser.uid);
        try {
          final snapshot = await docRef.get();
          if (!snapshot.exists) {
            print('⚠️ User doc does not exist for uid=${firebaseUser.uid}');
            yield null;
          } else {
            final data = snapshot.data()!;
            print('✅ Fetched user data: $data');

            // Safely extract each field, with defaults if missing
            final user = MyUser(
              userId: data['userId'] as String? ?? firebaseUser.uid,
              email: data['email'] as String? ?? firebaseUser.email ?? '',
              name: data['name'] as String? ?? '',
              url: data['url'] as String? ?? '',
              isSub: data['isSub'] as bool? ?? false,
              defaultAddressId: data['defaultAddressId'] as String?,
              blocked:
                  (data['blocked'] as List<dynamic>?)
                      ?.map((e) => e as String)
                      .toList() ??
                  <String>[],
            );

            yield user;
          }
        } catch (e, st) {
          print('❌ Error loading user doc: $e\n$st');
          yield null;
        }
      }
    });
  }

  Future updateUser(MyUser myUser, String password) async {
    try {
      await usersCollection
          .doc(myUser.userId)
          .update(myUser.toEntity().toDocument());
      await FirebaseAuth.instance.currentUser!.updatePassword(password);
    } catch (e) {
      // log(e.toString());
      rethrow;
    }

    return myUser;
  }

  Future signUp(MyUser myUser, String password) async {
    try {
      UserCredential user = await _firebaseAuth.createUserWithEmailAndPassword(
        email: myUser.email,
        password: password,
      );

      myUser.userId = user.user!.uid;

      try {
        // await user.user!.updateDisplayName(myUser.name);
        // await user.user!.updatePhotoURL(myUser.url);
        await usersCollection.doc(myUser.userId).set({
          ...myUser.toEntity().toDocument(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        // log(e.toString());
        rethrow;
      }
      await user.user!.updateDisplayName(myUser.name);
      await user.user!.updatePhotoURL(myUser.url);
      return myUser;
    } catch (e) {
      return null;
    }
  }

  Future signIn(String email, String password) async {
    try {
      var result = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      var user = result.user;
      print(user);
      return user;
    } catch (e) {
      return null;
    }
  }
}
