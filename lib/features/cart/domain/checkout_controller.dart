import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerece_app/features/cart/domain/checkout_repository.dart';
import 'package:ecommerece_app/core/providers/firebase_providers.dart';

final checkoutControllerProvider = AsyncNotifierProvider<CheckoutController, Map<String, dynamic>?>(() {
  return CheckoutController();
});

class CheckoutController extends AsyncNotifier<Map<String, dynamic>?> {
  @override
  Future<Map<String, dynamic>?> build() async {
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return null;
    }
    final repo = ref.read(checkoutRepositoryProvider);
    return await repo.getCachedUserValues(user.uid);
  }

  Future<Map<String, dynamic>?> loadCachedValues(String uid) async {
    final repo = ref.read(checkoutRepositoryProvider);
    final data = await repo.getCachedUserValues(uid);
    state = AsyncData(data);
    return data;
  }

  Future<bool> saveCachedUserValues(Map<String, dynamic> data) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return false;

    try {
      final repo = ref.read(checkoutRepositoryProvider);
      await repo.saveCachedUserValues(user.uid, data);
      
      // Update local state for immediate feedback/usage
      if (state.value != null) {
        state = AsyncData({...state.value!, ...data});
      } else {
        state = AsyncData(data);
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}
