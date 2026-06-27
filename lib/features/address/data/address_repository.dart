import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/features/address/domain/models/address.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerece_app/core/providers/firebase_providers.dart';

class AddressRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId;

  AddressRepository({required String userId}) : _userId = userId;

  CollectionReference get _addressesCollection =>
      _firestore.collection('users').doc(_userId).collection('addresses');

  DocumentReference get _userDocument =>
      _firestore.collection('users').doc(_userId);

  Future<List<Address>> getAddresses() async {
    final snapshot =
        await _addressesCollection.orderBy('createdAt', descending: true).get();
    return snapshot.docs
        .map((doc) => Address.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<bool> deleteAddress(String addressId) async {
    try {
      DocumentSnapshot userDoc = await _userDocument.get();
      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
      String? defaultAddressId = userData?['defaultAddressId'];

      WriteBatch batch = _firestore.batch();
      batch.delete(_addressesCollection.doc(addressId));

      if (defaultAddressId == addressId) {
        QuerySnapshot remainingAddresses =
            await _addressesCollection
                .orderBy('createdAt', descending: true)
                .get();

        DocumentSnapshot? nextDefault;
        for (var doc in remainingAddresses.docs) {
          if (doc.id != addressId) {
            nextDefault = doc;
            break;
          }
        }

        if (nextDefault != null) {
          batch.update(_userDocument, {'defaultAddressId': nextDefault.id});
          batch.update(nextDefault.reference, {'isDefault': true});
        } else {
          batch.update(_userDocument, {'defaultAddressId': null});
        }
      }

      await batch.commit();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> setAsDefaultAddress(String addressId) async {
    try {
      WriteBatch batch = _firestore.batch();

      QuerySnapshot defaultAddresses =
          await _addressesCollection.where('isDefault', isEqualTo: true).get();

      for (var doc in defaultAddresses.docs) {
        if (doc.id != addressId) {
          batch.update(doc.reference, {'isDefault': false});
        }
      }

      batch.update(_addressesCollection.doc(addressId), {'isDefault': true});
      batch.update(_userDocument, {'defaultAddressId': addressId});

      await batch.commit();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> resetAllDefaultFlags() async {
    QuerySnapshot addressesSnapshot = await _addressesCollection.get();

    WriteBatch batch = _firestore.batch();
    for (var doc in addressesSnapshot.docs) {
      if (doc.get('isDefault') == true) {
        batch.update(doc.reference, {'isDefault': false});
      }
    }

    if (addressesSnapshot.docs.isNotEmpty) {
      await batch.commit();
    }
  }

  Future<Address?> getDefaultAddress() async {
    try {
      DocumentSnapshot userDoc = await _userDocument.get();
      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
      String? defaultAddressId = userData?['defaultAddressId'];

      if (defaultAddressId != null) {
        DocumentSnapshot addressDoc =
            await _addressesCollection.doc(defaultAddressId).get();
        if (addressDoc.exists) {
          return Address.fromMap(addressDoc.data() as Map<String, dynamic>);
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}

final addressRepositoryProvider = Provider<AddressRepository>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    throw Exception('User not logged in');
  }
  return AddressRepository(userId: user.uid);
});
