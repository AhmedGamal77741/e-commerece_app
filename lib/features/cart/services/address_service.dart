import 'package:ecommerece_app/features/cart/models/address.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId;

  AddressService({required String userId}) : _userId = userId;

  // Collection reference for addresses
  CollectionReference get _addressesCollection =>
      _firestore.collection('users').doc(_userId).collection('addresses');

  // Reference to the user document
  DocumentReference get _userDocument =>
      _firestore.collection('users').doc(_userId);

  // Delete an address
  Future<bool> deleteAddress(BuildContext context, String addressId) async {
    try {
      // Check if we're deleting the default address
      DocumentSnapshot userDoc = await _userDocument.get();
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String? defaultAddressId = userData['defaultAddressId'];

      // Use a batch write to ensure consistency
      WriteBatch batch = _firestore.batch();

      // Delete the address
      batch.delete(_addressesCollection.doc(addressId));

      // If we're deleting the default address, clear the defaultAddressId
      if (defaultAddressId == addressId) {
        batch.update(_userDocument, {'defaultAddressId': null});
      }

      // Commit the batch
      await batch.commit();

      // Show success message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Address deleted successfully')));

      return true;
    } catch (e) {
      print(e);
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error setting default address: ${e.toString()}'),
        ),
      );
      return false;
    }
  }

  // Set address as default
  Future<bool> setAsDefaultAddress(
    BuildContext context,
    String addressId,
  ) async {
    try {
      // Use a batch write to update all addresses
      WriteBatch batch = _firestore.batch();

      // First, get all addresses
      QuerySnapshot addressesSnapshot = await _addressesCollection.get();

      // Set all addresses to non-default
      for (var doc in addressesSnapshot.docs) {
        batch.update(doc.reference, {'isDefault': false});
      }

      // Set the selected address as default

      // Commit the batch
      await batch.commit();

      // Update the user document with the new default address ID
      await _userDocument.update({'defaultAddressId': addressId});

      // Also update the isDefault field in the address document if needed
      await _addressesCollection.doc(addressId).update({'isDefault': true});

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Default address updated successfully')),
      );

      return true;
    } catch (e) {
      print(e);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error setting default address: ${e.toString()}'),
        ),
      );

      return false;
    }
  }

  // Helper method to reset isDefault flag on all addresses
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

  // Get the currently default address
  Future<Address?> getDefaultAddress() async {
    try {
      DocumentSnapshot userDoc = await _userDocument.get();
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String? defaultAddressId = userData['defaultAddressId'];

      if (defaultAddressId != null) {
        DocumentSnapshot addressDoc =
            await _addressesCollection.doc(defaultAddressId).get();
        if (addressDoc.exists) {
          return Address.fromMap(addressDoc.data() as Map<String, dynamic>);
        }
      }

      return null;
    } catch (e) {
      print('Error fetching default address: $e');
      return null;
    }
  }
}
