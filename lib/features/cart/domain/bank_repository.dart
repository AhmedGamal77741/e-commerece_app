import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final bankRepositoryProvider = Provider<BankRepository>((ref) {
  return BankRepository();
});

class BankRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> userBankAccountsStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snap) {
      if (!snap.exists) return [];
      final data = snap.data();
      if (data == null || !data.containsKey('bankAccounts')) return [];
      return List<Map<String, dynamic>>.from(data['bankAccounts'] as List);
    });
  }

  Future<void> deleteBankAccount(String uid, String payerId) async {
    final userRef = _firestore.collection('users').doc(uid);
    final snap = await userRef.get();
    final data = snap.data();
    if (data == null) return;

    final accounts = List<Map<String, dynamic>>.from(
      data['bankAccounts'] ?? [],
    );
    accounts.removeWhere((b) => b['payerId'] == payerId);
    await userRef.update({'bankAccounts': accounts});
  }
}
