import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/core/providers/firebase_providers.dart';
import 'package:ecommerece_app/features/review/data/review_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final reviewControllerProvider = Provider<ReviewController>((ref) {
  return ReviewController(ref);
});

final userOrdersStreamProvider =
    StreamProvider.autoDispose<List<QueryDocumentSnapshot>>((ref) {
      final user = ref.watch(authStateProvider).value;
      if (user == null) return Stream.value([]);

      final repo = ref.watch(reviewRepositoryProvider);
      return repo
          .getUserOrdersStream(user.uid)
          .map((snapshot) => snapshot.docs);
    });

// Cache provider for product fetching in orders
final orderProductProvider = FutureProvider.family
    .autoDispose<Map<String, dynamic>?, String>((ref, productId) {
      final repo = ref.watch(reviewRepositoryProvider);
      return repo.getProduct(productId);
    });

class ReviewController {
  final Ref _ref;

  ReviewController(this._ref);

  Future<void> submitExchangeRequest(String orderId, String reason) async {
    final user = _ref.read(authStateProvider).value;
    if (user == null) throw Exception('User not signed in');

    final repo = _ref.read(reviewRepositoryProvider);
    final orderData = await repo.getOrder(orderId);
    if (orderData == null) {
      throw Exception('이 주문 정보를 찾을 수 없습니다.');
    }

    final orderDateStr = orderData['orderDate'];
    if (orderDateStr == null) {
      throw Exception('이 주문은 교환을 신청할 수 없습니다.');
    }

    final orderDate = DateTime.tryParse(orderDateStr);
    if (orderDate == null) throw Exception('주문 날짜 형식이 잘못되었습니다.');

    final now = DateTime.now();
    if (now.difference(orderDate).inDays > 7) {
      throw Exception('주문 후 7일이 경과하여 교환할 수 없습니다.');
    }

    await repo.submitExchangeRequest(user.uid, orderId, reason);
  }

  Future<void> submitRefundRequest(String orderId, String reason) async {
    final user = _ref.read(authStateProvider).value;
    if (user == null) throw Exception('User not signed in');

    final repo = _ref.read(reviewRepositoryProvider);
    final orderData = await repo.getOrder(orderId);
    if (orderData == null) {
      throw Exception('이 주문 정보를 찾을 수 없습니다.');
    }

    final orderDateStr = orderData['orderDate'];
    if (orderDateStr == null) {
      throw Exception('이 주문은 반품을 신청할 수 없습니다.');
    }

    final orderDate = DateTime.tryParse(orderDateStr);
    if (orderDate == null) throw Exception('주문 날짜 형식이 잘못되었습니다.');

    final now = DateTime.now();
    if (now.difference(orderDate).inDays > 7) {
      throw Exception('주문 후 7일이 경과하여 반품할 수 없습니다.');
    }

    await repo.submitRefundRequest(user.uid, orderId, reason);
  }

  Future<void> submitReview(Map<String, dynamic> reviewData) async {
    final repo = _ref.read(reviewRepositoryProvider);
    await repo.submitReview(reviewData);
  }

  Future<void> cancelOrder(String orderId) async {
    final user = _ref.read(authStateProvider).value;
    if (user == null) throw Exception('User not signed in');

    final repo = _ref.read(reviewRepositoryProvider);
    final data = await repo.requestRefundFunction(user.uid, orderId);

    if ((data['status'] != 'refunded' && data['status'] != 'canceled')) {
      throw Exception('환불 처리에 실패했습니다. 고객센터에 문의해주세요.');
    }
  }
}
