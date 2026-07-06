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
        .map(
          (doc) => Address.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();
  }

  Stream<List<Address>> addressesStream() {
    return _addressesCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => Address.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    ),
                  )
                  .toList(),
        );
  }

  Future<void> addAddress({
    required String name,
    required String phone,
    required String address,
    required String detailAddress,
    required bool isDefaultAddress,
    required Map<String, dynamic> addressMap,
  }) async {
    final addressesSnapshot = await _addressesCollection.limit(1).get();
    final bool isFirstAddress = addressesSnapshot.docs.isEmpty;
    final bool shouldBeDefault = isDefaultAddress || isFirstAddress;

    final batch = _firestore.batch();

    if (shouldBeDefault && !isFirstAddress) {
      final defaultAddresses =
          await _addressesCollection.where('isDefault', isEqualTo: true).get();
      for (var doc in defaultAddresses.docs) {
        batch.update(doc.reference, {'isDefault': false});
      }
    }

    final docRef = _addressesCollection.doc();
    final addressData = {
      'id': docRef.id,
      'name': name,
      'phone': phone,
      'address': address,
      'detailAddress': detailAddress,
      'isDefault': shouldBeDefault,
      'addressMap': addressMap,
      'createdAt': FieldValue.serverTimestamp(),
    };

    batch.set(docRef, addressData);

    if (shouldBeDefault) {
      batch.set(_userDocument, {
        'defaultAddressId': docRef.id,
      }, SetOptions(merge: true));
    }

    await batch.commit();
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
          batch.set(_userDocument, {
            'defaultAddressId': nextDefault.id,
          }, SetOptions(merge: true));
          batch.set(nextDefault.reference, {
            'isDefault': true,
          }, SetOptions(merge: true));
        } else {
          batch.set(_userDocument, {
            'defaultAddressId': null,
          }, SetOptions(merge: true));
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
          batch.set(doc.reference, {
            'isDefault': false,
          }, SetOptions(merge: true));
        }
      }

      batch.set(_addressesCollection.doc(addressId), {
        'isDefault': true,
      }, SetOptions(merge: true));
      batch.set(_userDocument, {
        'defaultAddressId': addressId,
      }, SetOptions(merge: true));

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
        batch.set(doc.reference, {'isDefault': false}, SetOptions(merge: true));
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
          return Address.fromMap(
            addressDoc.data() as Map<String, dynamic>,
            addressDoc.id,
          );
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
