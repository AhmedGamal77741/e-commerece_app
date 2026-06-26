import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(FirebaseAuth.instance, FirebaseFirestore.instance);
});

class ProfileRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  ProfileRepository(this._auth, this._firestore);

  Future<void> softDeleteUser(String userId, String reason) async {
    final docRef = _firestore.collection('deletes').doc();
    final deleteData = {
      'deleteId': docRef.id,
      'userId': userId,
      'reason': reason,
      'createdAt': DateTime.now().toIso8601String(),
    };
    await docRef.set(deleteData);

    await _firestore.collection('users').doc(userId).update({
      'deleted': true,
      'deletedAt': DateTime.now().toIso8601String(),
    });

    await _auth.signOut();
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> reauthenticateUser(String email, String password) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("No user is currently signed in.");
    
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);
  }

  Future<void> updateSubscriptionStatus(String userId, bool isSub) async {
    await _firestore.collection('users').doc(userId).update({'isSub': isSub});
  }

  Future<void> cancelSubscription(String userId, String reason) async {
    final subSnap = await _firestore
        .collection('subscriptions')
        .where('userId', isEqualTo: userId)
        .orderBy('nextBillingDate', descending: true)
        .limit(1)
        .get();

    final docRef = _firestore.collection('cancels').doc();
    final cancelData = {
      'cancelId': docRef.id,
      'userId': userId,
      'reason': reason.trim(),
      'createdAt': DateTime.now().toIso8601String(),
    };

    await docRef.set(cancelData);

    if (subSnap.docs.isNotEmpty) {
      await subSnap.docs.first.reference.update({
        'status': 'canceled',
      });
    }
  }
}
