import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/core/providers/firebase_providers.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    firebaseAuth: ref.watch(authProvider),
    firestore: ref.watch(firestoreProvider),
    storage: ref.watch(storageProvider),
  );
});

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  AuthRepository({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  })  : _firebaseAuth = firebaseAuth,
        _firestore = firestore,
        _storage = storage;

  CollectionReference get usersCollection => _firestore.collection('users');

  /// Sign in with email and password
  Future<UserCredential> signIn(String email, String password) async {
    return await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Check if a nickname (tag) is taken
  Future<bool> isNicknameTaken(String name) async {
    final query = await usersCollection.where('tag', isEqualTo: name).limit(1).get();
    return query.docs.isNotEmpty;
  }

  /// Check if a phone number is taken
  Future<bool> isPhoneNumberTaken(String phoneNumber) async {
    final query = await usersCollection.where('phoneNumber', isEqualTo: phoneNumber).limit(1).get();
    return query.docs.isNotEmpty;
  }

  /// Sign up user
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    return await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Save user to Firestore
  Future<void> saveUserToFirestore(MyUser user) async {
    await usersCollection.doc(user.userId).set({
      ...user.toEntity().toDocument(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update an existing user in Firestore
  Future<void> updateUserInFirestore(MyUser user) async {
    await usersCollection.doc(user.userId).update(user.toEntity().toDocument());
  }

  /// Update auth profile (displayName, photoUrl)
  Future<void> updateAuthProfile({String? displayName, String? photoUrl}) async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      if (displayName != null) await user.updateDisplayName(displayName);
      if (photoUrl != null) await user.updatePhotoURL(photoUrl);
    }
  }

  /// Update auth password
  Future<void> updatePassword(String newPassword) async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      await user.updatePassword(newPassword);
    }
  }

  /// Send password reset email
  Future<void> sendPasswordReset(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  /// Upload an image to Firebase Storage and return the download URL
  Future<String> uploadProfileImage(XFile image, String userId) async {
    final originalBytes = await image.readAsBytes();
    Uint8List uploadBytes;
    try {
      final compressedBytes = await FlutterImageCompress.compressWithList(
        originalBytes,
        minWidth: 200,
        minHeight: 200,
        quality: 80,
        format: CompressFormat.jpeg,
      );
      uploadBytes = compressedBytes;
    } catch (e) {
      uploadBytes = originalBytes;
    }

    final String originalName = image.name;
    final int dotIndex = originalName.lastIndexOf('.');
    final String originalExtension = dotIndex != -1 
        ? originalName.substring(dotIndex).toLowerCase() 
        : '';

    String contentType = 'image/jpeg';
    String finalExtension = '.jpg';

    if (uploadBytes == originalBytes) {
      if (originalExtension == '.png') {
        contentType = 'image/png';
        finalExtension = '.png';
      } else if (originalExtension == '.webp') {
        contentType = 'image/webp';
        finalExtension = '.webp';
      } else if (originalExtension == '.gif') {
        contentType = 'image/gif';
        finalExtension = '.gif';
      } else if (originalExtension == '.heic' || originalExtension == '.heif') {
        throw Exception('Failed to compress/convert HEIC profile image to JPEG');
      }
    }

    final storageRef = _storage.ref().child('user_profile_images').child('$userId$finalExtension');
    final uploadTask = await storageRef.putData(
      uploadBytes,
      SettableMetadata(contentType: contentType),
    );
    final downloadUrl = await uploadTask.ref.getDownloadURL();
    return downloadUrl;
  }
}
