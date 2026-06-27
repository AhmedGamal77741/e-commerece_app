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
    return repo.getAddresses();
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
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(addressRepositoryProvider);
      final success = await repo.deleteAddress(addressId);
      if (!success) {
        throw Exception('Failed to delete address');
      }
      return _fetchAddresses();
    });
  }

  Future<void> setAsDefaultAddress(String addressId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(addressRepositoryProvider);
      final success = await repo.setAsDefaultAddress(addressId);
      if (!success) {
        throw Exception('Failed to set default address');
      }
      return _fetchAddresses();
    });
  }

  Future<void> refreshAddresses() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchAddresses());
  }
}

final defaultAddressProvider = FutureProvider<Address?>((ref) async {
  final repo = ref.watch(addressRepositoryProvider);
  return repo.getDefaultAddress();
});
