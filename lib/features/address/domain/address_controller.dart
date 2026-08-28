import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:ecommerece_app/features/address/domain/models/address.dart';
import 'package:ecommerece_app/features/address/data/address_repository.dart';

final addressesStreamProvider = StreamProvider<List<Address>>((ref) {
  final repo = ref.watch(addressRepositoryProvider);
  return repo.addressesStream();
});

final addressControllerProvider =
    AsyncNotifierProvider<AddressController, List<Address>>(() {
      return AddressController();
    });

class AddressController extends AsyncNotifier<List<Address>> {
  @override
  FutureOr<List<Address>> build() async {
    final addresses = await ref.watch(addressesStreamProvider.future);

    // Sort addresses: default address first
    final List<Address> sorted = List<Address>.from(addresses);
    sorted.sort((a, b) {
      if (a.isDefault && !b.isDefault) return -1;
      if (!a.isDefault && b.isDefault) return 1;
      return 0;
    });

    return sorted;
  }

  Future<void> addAddress({
    required String name,
    required String phone,
    required String address,
    required String detailAddress,
    required bool isDefaultAddress,
    required Map<String, dynamic> addressMap,
  }) async {
    final repo = ref.read(addressRepositoryProvider);
    await repo.addAddress(
      name: name,
      phone: phone,
      address: address,
      detailAddress: detailAddress,
      isDefaultAddress: isDefaultAddress,
      addressMap: addressMap,
    );
  }

  Future<void> updateAddress({
    required String addressId,
    required String name,
    required String phone,
    required String address,
    required String detailAddress,
    required bool isDefaultAddress,
    required Map<String, dynamic> addressMap,
  }) async {
    final repo = ref.read(addressRepositoryProvider);
    await repo.updateAddress(
      addressId: addressId,
      name: name,
      phone: phone,
      address: address,
      detailAddress: detailAddress,
      isDefaultAddress: isDefaultAddress,
      addressMap: addressMap,
    );
  }

  Future<void> deleteAddress(String addressId) async {
    final repo = ref.read(addressRepositoryProvider);
    final success = await repo.deleteAddress(addressId);
    if (!success) {
      throw Exception('Failed to delete address');
    }
  }

  Future<void> setAsDefaultAddress(String addressId) async {
    final repo = ref.read(addressRepositoryProvider);
    final success = await repo.setAsDefaultAddress(addressId);
    if (!success) {
      throw Exception('Failed to set default address');
    }
  }

  Future<void> refreshAddresses() async {
    // No-op because the stream updates state automatically
  }
}

final defaultAddressProvider = FutureProvider<Address?>((ref) async {
  final repo = ref.watch(addressRepositoryProvider);
  return repo.getDefaultAddress();
});
