import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/core/providers/firebase_providers.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerece_app/core/helpers/image_upload_helper.dart';

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

  /// Check if a nickname (name) is taken
  Future<bool> isNicknameTaken(String name) async {
    final query = await usersCollection.where('name', isEqualTo: name).limit(1).get();
    return query.docs.isNotEmpty;
  }

  /// Check if a phone number is taken
  Future<bool> isPhoneNumberTaken(String phoneNumber) async {
    final query = await usersCollection.where('phoneNumber', isEqualTo: phoneNumber).limit(1).get();
    return query.docs.isNotEmpty;
  }

  /// Check if an email is registered
  Future<bool> isEmailRegistered(String email) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty) return false;

    final lowerEmail = cleanEmail.toLowerCase();

    // 1. Direct match with entered email
    final query =
        await usersCollection
            .where('email', isEqualTo: cleanEmail)
            .limit(1)
            .get();
    if (query.docs.isNotEmpty) {
      return true;
    }

    // 2. Direct match with lowercased email
    if (cleanEmail != lowerEmail) {
      final queryLower =
          await usersCollection
              .where('email', isEqualTo: lowerEmail)
              .limit(1)
              .get();
      if (queryLower.docs.isNotEmpty) {
        return true;
      }
    }

    // 3. Match with capitalized email (e.g., User@domain.com)
    final capitalized =
        lowerEmail.isNotEmpty
            ? '${lowerEmail[0].toUpperCase()}${lowerEmail.substring(1)}'
            : lowerEmail;
    if (capitalized != cleanEmail && capitalized != lowerEmail) {
      final queryCap =
          await usersCollection
              .where('email', isEqualTo: capitalized)
              .limit(1)
              .get();
      if (queryCap.docs.isNotEmpty) {
        return true;
      }
    }

    return false;
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
    final preparedData = await ImageUploadHelper.prepareImageForUpload(
      rawBytes: originalBytes,
      originalName: image.name,
      minWidth: 200,
      minHeight: 200,
      quality: 80,
    );

    final storageRef = _storage.ref().child('user_profile_images').child('$userId${preparedData.extension}');
    final uploadTask = await storageRef.putData(
      preparedData.bytes,
      SettableMetadata(contentType: preparedData.contentType),
    );
    final downloadUrl = await uploadTask.ref.getDownloadURL();
    return downloadUrl;
  }
}
