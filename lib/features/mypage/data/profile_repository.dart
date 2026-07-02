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

  Future<void> recoverUserAccount(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'deleted': FieldValue.delete(),
        'deletedAt': FieldValue.delete(),
      });
      final query = await _firestore.collection('deletes').where('userId', isEqualTo: userId).get();
      for (final doc in query.docs) {
        await doc.reference.delete();
      }
    } catch (_) {}
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

  /// Check if user has a bank account registered.
  Future<bool> checkBankAccount(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final data = userDoc.data();
    final accounts = data?['bankAccounts'];
    return accounts != null && accounts is List && accounts.isNotEmpty;
  }

  /// Re-check bank account after returning from NoBankAccountScreen.
  Future<bool> refreshBankAccount(String userId) async {
    final refreshed = await _firestore.collection('users').doc(userId).get();
    final refreshedAccounts = refreshed.data()?['bankAccounts'];
    return refreshedAccounts != null && refreshedAccounts is List && refreshedAccounts.isNotEmpty;
  }

  /// Check if user has valid receipt data in usercached_values.
  Future<bool> checkReceiptData(String userId) async {
    try {
      final doc = await _firestore.collection('usercached_values').doc(userId).get();
      if (!doc.exists) return false;
      final data = doc.data();
      if (data == null) return false;

      final name = data['name'] as String?;
      final phone = data['phone'] as String?;
      if (name != null && name.trim().isNotEmpty &&
          phone != null && phone.trim().isNotEmpty) {
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getReceiptData(String userId) async {
    try {
      final doc = await _firestore.collection('usercached_values').doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveReceiptData(String userId, Map<String, dynamic> data) async {
    await _firestore.collection('usercached_values').doc(userId).set(data, SetOptions(merge: true));
  }
}
