import 'package:ecommerece_app/core/providers/firebase_providers.dart';
import 'package:ecommerece_app/features/chat/models/chat_room_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final unreadChatRoomsProvider = StreamProvider.autoDispose<bool>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(false);

  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('chatRooms')
      .where('participants', arrayContains: user.uid)
      .snapshots()
      .map((snapshot) {
        final chatRooms =
            snapshot.docs
                .map((doc) => ChatRoomModel.fromMap(doc.data()))
                .toList();
        return chatRooms.any(
          (room) =>
              !room.deletedBy.contains(user.uid) &&
              (room.unreadCount[user.uid] ?? 0) > 0,
        );
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
