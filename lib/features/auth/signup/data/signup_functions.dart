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
    return _firebaseAuth.authStateChanges().flatMap((firebaseUser) async* {
      if (firebaseUser == null) {
        yield MyUser.empty;
      } else {
        yield await usersCollection
            .doc(firebaseUser.uid)
            .get()
            .then(
              (val) =>
                  MyUser.fromEntity(MyUserEntity.fromDocument(val.data()!)),
            );
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
        await usersCollection
            .doc(myUser.userId)
            .set(myUser.toEntity().toDocument());
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
      return user;
    } catch (e) {
      return null;
    }
  }
}
