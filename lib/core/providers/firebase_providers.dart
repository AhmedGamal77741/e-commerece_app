import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the global instance of [FirebaseFirestore].
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Provides the global instance of [FirebaseAuth].
final authProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Provides the global instance of [FirebaseStorage].
final storageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

/// Stream provider for the current Firebase User's authentication state.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authProvider).authStateChanges();
});

/// Provider for the current User's ID (uid). Returns an empty string if not logged in.
final currentUserIdProvider = Provider<String>((ref) {
  final user = ref.watch(authStateProvider).value;
  return user?.uid ?? '';
});

/// Stream provider for the current user's profile document data.
final userProfileStreamProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(null);
  
  return ref.watch(firestoreProvider)
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((doc) => doc.data());
});
