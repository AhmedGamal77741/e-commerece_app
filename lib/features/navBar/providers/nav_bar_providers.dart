import 'package:ecommerece_app/core/providers/firebase_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final unreadChatRoomsProvider = StreamProvider.autoDispose<bool>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(false);

  final uid = user.uid;
  final firestore = ref.watch(firestoreProvider);
  // Limit to 50 most recent rooms — avoids downloading entire chat history.
  // For the badge we only need to know if ANY room has unread messages.
  return firestore
      .collection('chatRooms')
      .where('participants', arrayContains: uid)
      .limit(50)
      .snapshots()
      .map((snapshot) {
        for (final doc in snapshot.docs) {
          final data = doc.data();
          // Skip rooms deleted by this user
          final deletedBy = data['deletedBy'];
          if (deletedBy is List && deletedBy.contains(uid)) continue;
          // Check unread count directly from the raw map — no full model parsing needed
          final unreadCount = data['unreadCount'];
          if (unreadCount is Map && (unreadCount[uid] ?? 0) > 0) return true;
        }
        return false;
      });
});

final navBarServiceProvider = Provider<NavBarService>((ref) {
  return NavBarService(ref);
});

class NavBarService {
  final Ref ref;
  NavBarService(this.ref);

  Future<bool> hasBankAccount(String uid) async {
    final firestore = ref.read(firestoreProvider);
    final userDoc = await firestore.collection('users').doc(uid).get();
    final data = userDoc.data();
    final accounts = data?['bankAccounts'];
    return accounts != null && accounts is List && accounts.isNotEmpty;
  }

  Future<bool> isAccountDeleted(String uid) async {
    final firestore = ref.read(firestoreProvider);
    final userDoc = await firestore.collection('users').doc(uid).get();
    final data = userDoc.data();
    return data != null && data['deleted'] == true;
  }

  Future<bool> hasReceiptData(String uid) async {
    final firestore = ref.read(firestoreProvider);
    final cacheDoc =
        await firestore.collection('usercached_values').doc(uid).get();
    final cacheData = cacheDoc.data();
    return cacheData != null &&
        (cacheData['selectedOption'] == 1 ||
            cacheData['selectedOption'] == 2) &&
        (cacheData['name'] as String? ?? '').isNotEmpty &&
        (cacheData['email'] as String? ?? '').isNotEmpty &&
        (cacheData['phone'] as String? ?? '').isNotEmpty;
  }

  Future<bool> hasDefaultAddress(String uid) async {
    final firestore = ref.read(firestoreProvider);
    final userDoc = await firestore.collection('users').doc(uid).get();
    final data = userDoc.data();
    return data != null &&
        data['defaultAddressId'] != null &&
        data['defaultAddressId'] != '';
  }

  Future<void> recoverAccount(String uid) async {
    final firestore = ref.read(firestoreProvider);
    await firestore.collection('users').doc(uid).update({
      'deleted': false,
      'deletedAt': null,
    });
  }

  Future<void> signOut() async {
    await ref.read(authProvider).signOut();
  }
}
