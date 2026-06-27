import 'package:ecommerece_app/core/models/product_model.dart';
import 'package:ecommerece_app/core/providers/firebase_providers.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/features/shop/domain/shop_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class BottomActionButtons extends ConsumerStatefulWidget {
  final Product product;
  final String? selectedOption;
  final bool isSub;

  const BottomActionButtons({
    super.key,
    required this.product,
    required this.selectedOption,
    required this.isSub,
  });

  @override
  ConsumerState<BottomActionButtons> createState() => _BottomActionButtonsState();
}

class _BottomActionButtonsState extends ConsumerState<BottomActionButtons> {
  void _showQuantityRequiredMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('수량을 선택해주세요!'),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<int?> _getValidatedStock(PricePoint pricePoint) async {
    final currentStock = await ref
        .read(shopControllerProvider.notifier)
        .getValidatedStock(widget.product.product_id, pricePoint.quantity);
    if (currentStock == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('수량 부족'), backgroundColor: Colors.red),
        );
      }
      return null;
    }
    return currentStock;
  }

  Future<void> _handleBuyNow({
    required String uid,
    required PricePoint pricePoint,
  }) async {
    final paymentId = await ref
        .read(shopControllerProvider.notifier)
        .processBuyNow(
          product: widget.product,
          pricePoint: pricePoint,
          pricePointIndex: int.parse(widget.selectedOption!),
          isSub: widget.isSub,
        );

    if (paymentId != null && mounted) {
      Navigator.pop(context); // Dismiss loading dialog
      context.go('/buy-now?paymentId=$paymentId');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authStateProvider).value;
    final isLoggedIn = currentUser != null;
    final uid = currentUser?.uid;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () async {
                  if (!isLoggedIn || uid == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("내 페이지 탭에서 회원가입 후 이용가능합니다")),
                    );
                    return;
                  }
                  if (widget.selectedOption == null) {
                    _showQuantityRequiredMessage();
                    return;
                  }
                  final pricePoint = widget.product
                      .pricePoints[int.parse(widget.selectedOption!)];
                  final currentStock = await _getValidatedStock(pricePoint);
                  if (currentStock == null) return;

                  final cartTotalQuantity = await ref
                      .read(shopControllerProvider.notifier)
                      .getCartItemQuantity(widget.product.product_id);

                  if (cartTotalQuantity + pricePoint.quantity > currentStock) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '해당 상품의 남은 수량은 ${currentStock - cartTotalQuantity}개 입니다.',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  await ref.read(shopControllerProvider.notifier).addToCart(
                        productId: widget.product.product_id,
                        pricePointIndex: int.parse(widget.selectedOption!),
                        deliveryManagerId:
                            widget.product.deliveryManagerId ?? '',
                        productName: widget.product.productName,
                      );
                  if (context.mounted) Navigator.pop(context);
                },
                style: TextButton.styleFrom(
                  backgroundColor: ColorsManager.white,
                  padding:
                      EdgeInsets.symmetric(horizontal: 6.w, vertical: 10.h),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  '장바구니 담기',
                  style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'NotoSans',
                    fontSize: 18.sp,
                  ),
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: TextButton(
                onPressed: () async {
                  if (!isLoggedIn || uid == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("내 페이지 탭에서 회원가입 후 이용가능합니다")),
                    );
                    return;
                  }
                  if (widget.selectedOption == null) {
                    _showQuantityRequiredMessage();
                    return;
                  }

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  );

                  try {
                    final pricePoint = widget.product
                        .pricePoints[int.parse(widget.selectedOption!)];
                    final currentStock = await _getValidatedStock(pricePoint);
                    if (currentStock == null) {
                      if (context.mounted) Navigator.pop(context); // Dismiss loading
                      return;
                    }

                    await _handleBuyNow(
                      uid: uid,
                      pricePoint: pricePoint,
                    );
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context); // Dismiss loading
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('오류가 발생했습니다: $e')),
                      );
                    }
                  }
                },
                style: TextButton.styleFrom(
                  backgroundColor: ColorsManager.primaryblack,
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  '바로 구매',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'NotoSans',
                    fontSize: 18.sp,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
