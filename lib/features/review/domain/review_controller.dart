import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/core/providers/firebase_providers.dart';
import 'package:ecommerece_app/features/review/data/review_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final reviewControllerProvider = AsyncNotifierProvider<ReviewController, void>(
  () {
    return ReviewController();
  },
);

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

/// Stream provider for a single order document (used by tracking table).
final orderDocStreamProvider = StreamProvider.family
    .autoDispose<Map<String, dynamic>?, String>((ref, orderId) {
      final repo = ref.watch(reviewRepositoryProvider);
      return repo.getOrderStream(orderId);
    });

class ReviewController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // No initial state needed — this controller is action-only.
  }

  Future<void> submitRequest(
    String orderId,
    Map<String, dynamic> requestData,
  ) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) throw Exception('User not signed in');

    final repo = ref.read(reviewRepositoryProvider);
    final orderData = await repo.getOrder(orderId);
    if (orderData == null) {
      throw Exception('이 주문 정보를 찾을 수 없습니다.');
    }

    final orderDateStr = orderData['orderDate'];
    if (orderDateStr == null) {
      throw Exception('이 주문은 취소/교환/환불을 신청할 수 없습니다.');
    }

    final orderDate = DateTime.tryParse(orderDateStr);
    if (orderDate == null) throw Exception('주문 날짜 형식이 잘못되었습니다.');

    final now = DateTime.now();
    if (now.difference(orderDate).inDays > 7) {
      throw Exception('주문 후 7일이 경과하여 신청할 수 없습니다.');
    }

    await repo.submitRequest(user.uid, orderId, requestData);
  }

  Future<void> submitReview(Map<String, dynamic> reviewData) async {
    final repo = ref.read(reviewRepositoryProvider);
    await repo.submitReview(reviewData);
  }

  Future<void> cancelOrder(String orderId) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) throw Exception('User not signed in');

    final repo = ref.read(reviewRepositoryProvider);
    final data = await repo.requestRefundFunction(user.uid, orderId);

    if ((data['status'] != 'refunded' && data['status'] != 'canceled')) {
      throw Exception('환불 처리에 실패했습니다. 고객센터에 문의해주세요.');
    }
  }
}
