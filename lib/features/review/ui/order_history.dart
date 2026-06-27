import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/providers/firebase_providers.dart';
import 'package:ecommerece_app/features/review/domain/review_controller.dart';
import 'package:ecommerece_app/features/review/ui/widgets/order_history/deleted_product_card.dart';
import 'package:ecommerece_app/features/review/ui/widgets/order_history/fade_in_wrapper.dart';
import 'package:ecommerece_app/features/review/ui/widgets/order_history/order_item_card.dart';
import 'package:ecommerece_app/features/review/ui/widgets/order_history/order_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ---------------------------------------------------------------------------
// OrderHistory — main page (lean scaffold that composes extracted widgets)
// ---------------------------------------------------------------------------
class OrderHistory extends ConsumerWidget {
  const OrderHistory({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return const Center(child: Text('내 페이지 탭에서 회원가입 후 이용가능합니다.'));
    }

    final ordersAsync = ref.watch(userOrdersStreamProvider);

    return ordersAsync.when(
      loading: () => const OrderSkeletonList(),
      error: (error, stack) => Center(child: Text('에러 발생: $error')),
      data: (orders) {
        if (orders.isEmpty) {
          return const Center(child: Text('주문 내역이 없습니다.'));
        }

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          child: ListView.separated(
            itemCount: orders.length,
            separatorBuilder: (_, __) => Divider(color: ColorsManager.primary300),
            itemBuilder: (context, index) {
              final data = orders[index].data() as Map<String, dynamic>;
              final productId = data['productId'] as String? ?? '';

              final productAsync = ref.watch(orderProductProvider(productId));

              return productAsync.when(
                loading: () => const OrderCardSkeleton(),
                error: (_, __) => FadeInWrapper(
                  delay: Duration(milliseconds: index * 60),
                  child: DeletedProductCard(orderData: data),
                ),
                data: (product) {
                  if (product == null || product.isEmpty) {
                    return FadeInWrapper(
                      delay: Duration(milliseconds: index * 60),
                      child: DeletedProductCard(orderData: data),
                    );
                  }

                  return FadeInWrapper(
                    delay: Duration(milliseconds: index * 60),
                    child: OrderItemCard(
                      orderData: data,
                      product: product,
                      user: user,
                      onDelete: () => _confirmAndCancelOrder(data, context, ref),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  /// Shows a confirmation dialog and cancels the order via the controller.
  void _confirmAndCancelOrder(
    Map<String, dynamic> order,
    BuildContext context,
    WidgetRef ref,
  ) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text(
              '주문 취소',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            content: const Text(
              '정말로 이 주문을 취소하시겠습니까?\n취소 후에는 복구가 불가능합니다.',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => navigator.pop(false),
                child: const Text('취소', style: TextStyle(color: Colors.black)),
              ),
              TextButton(
                style: TextButton.styleFrom(backgroundColor: Colors.black),
                onPressed: () => navigator.pop(true),
                child: const Text('확인', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      final orderId = order['orderId'] as String?;
      if (orderId == null) {
        navigator.pop();
        messenger.showSnackBar(
          const SnackBar(content: Text('이 주문은 취소할 수 없습니다.')),
        );
        return;
      }

      await ref.read(reviewControllerProvider.notifier).cancelOrder(orderId);

      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('주문이 성공적으로 취소되었습니다.')),
      );
    } catch (e) {
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text('주문 취소 중 에러가 발생했습니다: $e')),
      );
    }
  }
}
