import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:ecommerece_app/features/address/domain/models/address.dart';
import 'package:ecommerece_app/features/address/data/address_repository.dart';

final addressControllerProvider = AsyncNotifierProvider<AddressController, List<Address>>(() {
  return AddressController();
});

class AddressController extends AsyncNotifier<List<Address>> {
  @override
  FutureOr<List<Address>> build() async {
    return _fetchAddresses();
  }

  Future<List<Address>> _fetchAddresses() async {
    final repo = ref.read(addressRepositoryProvider);
    final addresses = await repo.getAddresses();
    
    // Sort addresses: default address first
    addresses.sort((a, b) {
      if (a.isDefault && !b.isDefault) return -1;
      if (!a.isDefault && b.isDefault) return 1;
      return 0;
    });
    
    return addresses;
  }

  Future<void> addAddress({
    required String name,
    required String phone,
    required String address,
    required String detailAddress,
    required bool isDefaultAddress,
    required Map<String, dynamic> addressMap,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(addressRepositoryProvider);
      await repo.addAddress(
        name: name,
        phone: phone,
        address: address,
        detailAddress: detailAddress,
        isDefaultAddress: isDefaultAddress,
        addressMap: addressMap,
      );
      return _fetchAddresses();
    });
  }

  Future<void> deleteAddress(String addressId) async {
    // Optimistically remove the address from the current state
    if (state.hasValue) {
      final currentList = state.value!;
      state = AsyncValue.data(currentList.where((a) => a.id != addressId).toList());
    }

    try {
      final repo = ref.read(addressRepositoryProvider);
      final success = await repo.deleteAddress(addressId);
      if (!success) {
        throw Exception('Failed to delete address');
      }
    } catch (e) {
      // Re-fetch to rollback if deletion failed
      final addresses = await _fetchAddresses();
      state = AsyncValue.data(addresses);
      rethrow;
    }
  }

  Future<void> setAsDefaultAddress(String addressId) async {
    // We update the data seamlessly without setting state to AsyncValue.loading()
    // Optimistic update for better UX
    if (state.hasValue) {
      final currentList = state.value!;
      final updatedList = currentList.map((a) {
        return a.copyWith(isDefault: a.id == addressId);
      }).toList();
      
      updatedList.sort((a, b) {
        if (a.isDefault && !b.isDefault) return -1;
        if (!a.isDefault && b.isDefault) return 1;
        return 0;
      });
      state = AsyncValue.data(updatedList);
    }

    try {
      final repo = ref.read(addressRepositoryProvider);
      final success = await repo.setAsDefaultAddress(addressId);
      if (!success) {
        throw Exception('Failed to set default address');
      }
      
      // Fetch fresh data in the background to ensure consistency
      final freshAddresses = await _fetchAddresses();
      state = AsyncValue.data(freshAddresses);
    } catch (e) {
      // Rollback
      final addresses = await _fetchAddresses();
      state = AsyncValue.data(addresses);
      rethrow;
    }
  }

  Future<void> refreshAddresses() async {
    // Seamless refresh without full loading spinner
    final addresses = await _fetchAddresses();
    state = AsyncValue.data(addresses);
  }
}

final defaultAddressProvider = FutureProvider<Address?>((ref) async {
  final repo = ref.watch(addressRepositoryProvider);
  return repo.getDefaultAddress();
});
