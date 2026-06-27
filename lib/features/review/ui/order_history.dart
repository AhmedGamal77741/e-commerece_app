import 'package:ecommerece_app/core/helpers/basetime.dart';
import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/core/widgets/black_text_button.dart';
import 'package:ecommerece_app/core/providers/firebase_providers.dart';
import 'package:ecommerece_app/features/review/domain/review_controller.dart';
import 'package:ecommerece_app/features/review/ui/exchange_or_refund.dart';
import 'package:ecommerece_app/features/review/ui/track_order.dart';
import 'package:ecommerece_app/features/review/ui/widgets/text_and_buttons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ---------------------------------------------------------------------------
// OrderHistory — main page
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
      loading: () => const _OrderSkeletonList(),
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
                loading: () => const _OrderCardSkeleton(),
                error: (_, __) => _FadeIn(
                  delay: Duration(milliseconds: index * 60),
                  child: _DeletedProductCard(orderData: data),
                ),
                data: (product) {
                  if (product == null || product.isEmpty) {
                    return _FadeIn(
                      delay: Duration(milliseconds: index * 60),
                      child: _DeletedProductCard(orderData: data),
                    );
                  }

                  return _FadeIn(
                    delay: Duration(milliseconds: index * 60),
                    child: _OrderItem(
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

// ---------------------------------------------------------------------------
// Fade-in wrapper — staggered reveal for each card
// ---------------------------------------------------------------------------
class _FadeIn extends ConsumerStatefulWidget {
  const _FadeIn({required this.child, this.delay = Duration.zero});
  final Widget child;
  final Duration delay;

  @override
  ConsumerState<_FadeIn> createState() => _FadeInState();
}

class _FadeInState extends ConsumerState<_FadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer skeleton — full page version shown on first load
// ---------------------------------------------------------------------------
class _OrderSkeletonList extends ConsumerWidget {
  const _OrderSkeletonList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        separatorBuilder: (_, __) => Divider(color: ColorsManager.primary300),
        itemBuilder: (_, index) => _ShimmerCard(index: index),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer card — each skeleton item animates with a staggered delay
// ---------------------------------------------------------------------------
class _ShimmerCard extends ConsumerStatefulWidget {
  const _ShimmerCard({required this.index});
  final int index;

  @override
  ConsumerState<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends ConsumerState<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Stagger each card's shimmer phase slightly
    _shimmer = Tween<double>(
      begin: -1.5,
      end: 2.5,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: AnimatedBuilder(
        animation: _shimmer,
        builder: (context, _) {
          final gradient = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: const [
              Color(0xFFE8E8E8),
              Color(0xFFF5F5F5),
              Color(0xFFE8E8E8),
            ],
            stops: [
              (_shimmer.value - 0.5).clamp(0.0, 1.0),
              _shimmer.value.clamp(0.0, 1.0),
              (_shimmer.value + 0.5).clamp(0.0, 1.0),
            ],
          );

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image placeholder
              Container(
                width: 120.w,
                height: 120.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: gradient,
                ),
              ),
              horizontalSpace(10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    verticalSpace(6),
                    // Seller name line
                    _ShimmerLine(gradient: gradient, width: 80.w, height: 11.h),
                    verticalSpace(8),
                    // Product name line
                    _ShimmerLine(
                      gradient: gradient,
                      width: 160.w,
                      height: 13.h,
                    ),
                    verticalSpace(8),
                    // Price line
                    _ShimmerLine(
                      gradient: gradient,
                      width: 100.w,
                      height: 11.h,
                    ),
                    verticalSpace(14),
                    // Buttons row
                    Row(
                      children: [
                        _ShimmerLine(
                          gradient: gradient,
                          width: 72.w,
                          height: 28.h,
                          radius: 6,
                        ),
                        horizontalSpace(8),
                        _ShimmerLine(
                          gradient: gradient,
                          width: 100.w,
                          height: 28.h,
                          radius: 6,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ShimmerLine extends ConsumerWidget {
  const _ShimmerLine({
    required this.gradient,
    required this.width,
    required this.height,
    this.radius = 4,
  });

  final LinearGradient gradient;
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: gradient,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Per-item skeleton (used while product data loads individually)
// ---------------------------------------------------------------------------
class _OrderCardSkeleton extends ConsumerStatefulWidget {
  const _OrderCardSkeleton();

  @override
  ConsumerState<_OrderCardSkeleton> createState() => _OrderCardSkeletonState();
}

class _OrderCardSkeletonState extends ConsumerState<_OrderCardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _shimmer = Tween<double>(
      begin: -1.5,
      end: 2.5,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: AnimatedBuilder(
        animation: _shimmer,
        builder: (context, _) {
          final gradient = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: const [
              Color(0xFFE8E8E8),
              Color(0xFFF5F5F5),
              Color(0xFFE8E8E8),
            ],
            stops: [
              (_shimmer.value - 0.5).clamp(0.0, 1.0),
              _shimmer.value.clamp(0.0, 1.0),
              (_shimmer.value + 0.5).clamp(0.0, 1.0),
            ],
          );
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 120.w,
                height: 120.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: gradient,
                ),
              ),
              horizontalSpace(10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    verticalSpace(6),
                    _ShimmerLine(gradient: gradient, width: 80.w, height: 11.h),
                    verticalSpace(8),
                    _ShimmerLine(
                      gradient: gradient,
                      width: 160.w,
                      height: 13.h,
                    ),
                    verticalSpace(8),
                    _ShimmerLine(
                      gradient: gradient,
                      width: 100.w,
                      height: 11.h,
                    ),
                    verticalSpace(14),
                    Row(
                      children: [
                        _ShimmerLine(
                          gradient: gradient,
                          width: 72.w,
                          height: 28.h,
                          radius: 6,
                        ),
                        horizontalSpace(8),
                        _ShimmerLine(
                          gradient: gradient,
                          width: 100.w,
                          height: 28.h,
                          radius: 6,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single order row
// ---------------------------------------------------------------------------
class _OrderItem extends ConsumerWidget {
  const _OrderItem({
    required this.orderData,
    required this.product,
    required this.user,
    required this.onDelete,
  });

  final Map<String, dynamic> orderData;
  final Map<String, dynamic> product;
  final User user;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            product['imgUrl'] ?? '',
            width: 120.w,
            height: 120.h,
            fit: BoxFit.cover,
            errorBuilder:
                (_, __, ___) => Container(
                  width: 120.w,
                  height: 120.h,
                  color: Colors.grey.shade200,
                  child: const Icon(
                    Icons.image_not_supported,
                    color: Colors.grey,
                  ),
                ),
          ),
        ),
        horizontalSpace(10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextAndButtons(
                sellerName: product['sellerName'] ?? '',
                productName: product['productName'] ?? '',
                qunatity: orderData['quantity'].toString(),
                orderPrice: orderData['totalPrice'],
                baselineTime: product['baselineTime'],
                meridiem: product['meridiem'],
              ),
              Row(
                children: [
                  BlackTextButton(
                    txt: '배송조회',
                    style: TextStyles.abeezee14px400wW,
                    func: () async {
                      final arrivalDate = await getArrivalDay2(
                        product['meridiem'],
                        product['baselineTime'],
                      );
                      if (!context.mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => TrackOrder(
                                order: orderData,
                                arrivalDate: arrivalDate,
                              ),
                        ),
                      );
                    },
                  ),
                  horizontalSpace(5),
                  if (orderData['confirmed'] == true) ...[
                    if (orderData['isRequested'] == true)
                      BlackTextButton(
                        txt: '교환 · 반품 신청',
                        style: TextStyles.abeezee14px400wW.copyWith(
                          decoration: TextDecoration.lineThrough,
                          decorationColor: Colors.red,
                          decorationThickness: 2,
                        ),
                        func: () {},
                      )
                    else
                      BlackTextButton(
                        txt: '교환 · 반품 신청',
                        style: TextStyles.abeezee14px400wW,
                        func: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => ExchangeOrRefund(
                                    userId: user.uid,
                                    orderId: orderData['orderId'],
                                  ),
                            ),
                          );
                        },
                      ),
                  ] else
                    BlackTextButton(
                      txt: '주문취소',
                      style: TextStyles.abeezee14px400wW,
                      func: onDelete,
                    ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: Icon(
            Icons.more_horiz,
            color: ColorsManager.primary600,
            size: 18,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Deleted product card
// ---------------------------------------------------------------------------
class _DeletedProductCard extends ConsumerWidget {
  const _DeletedProductCard({required this.orderData});
  final Map<String, dynamic> orderData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 80.w,
            height: 80.h,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.image_not_supported_outlined,
              color: Colors.grey.shade500,
              size: 32,
            ),
          ),
          horizontalSpace(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '판매 종료된 상품',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                verticalSpace(4),
                Text(
                  '이 상품은 더 이상 판매되지 않습니다.',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey.shade500,
                  ),
                ),
                verticalSpace(4),
                Text(
                  '결제금액: ₩${orderData['totalPrice']}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
