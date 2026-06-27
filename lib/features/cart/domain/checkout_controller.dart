import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  Future<Map<String, dynamic>?> getPendingBuynow(String uid, String paymentId) async {
    final repo = ref.read(checkoutRepositoryProvider);
    return await repo.getPendingBuynow(uid, paymentId);
  }

  Future<void> patchPendingBuynow(String uid, String paymentId, Map<String, dynamic> data) async {
    final repo = ref.read(checkoutRepositoryProvider);
    await repo.patchPendingBuynow(uid, paymentId, data);
  }

  Future<Map<String, dynamic>?> getUserDefaultAddress(String uid) async {
    final repo = ref.read(checkoutRepositoryProvider);
    return await repo.getUserDefaultAddress(uid);
  }

  String generateOrderId() {
    final repo = ref.read(checkoutRepositoryProvider);
    return repo.generateOrderId();
  }
  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserStream(String uid) {
    final repo = ref.read(checkoutRepositoryProvider);
    return repo.getUserStream(uid);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getUserCartStream(String uid) {
    final repo = ref.read(checkoutRepositoryProvider);
    return repo.getUserCartStream(uid);
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getProductFuture(String productId) {
    final repo = ref.read(checkoutRepositoryProvider);
    return repo.getProductFuture(productId);
  }
  Future<void> processCheckoutTransaction({
    required String uid,
    required String paymentId,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> orderData,
    required bool isCartCheckout,
  }) async {
    final repo = ref.read(checkoutRepositoryProvider);
    await repo.processCheckoutTransaction(
      uid: uid,
      paymentId: paymentId,
      items: items,
      orderData: orderData,
      isCartCheckout: isCartCheckout,
    );
  }
}

final checkoutUserStreamProvider = StreamProvider.family<dynamic, String>((ref, uid) {
  final repo = ref.read(checkoutRepositoryProvider);
  return repo.getUserStream(uid);
});

final checkoutCartStreamProvider = StreamProvider.family<dynamic, String>((ref, uid) {
  final repo = ref.read(checkoutRepositoryProvider);
  return repo.getUserCartStream(uid);
});

final checkoutProductFutureProvider = FutureProvider.family<dynamic, String>((ref, productId) {
  final repo = ref.read(checkoutRepositoryProvider);
  return repo.getProductFuture(productId);
});
