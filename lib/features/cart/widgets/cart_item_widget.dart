import 'package:ecommerece_app/core/helpers/basetime.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/features/auth/domain/auth_controller.dart';
import 'package:ecommerece_app/features/cart/domain/cart_controller.dart';
import 'package:go_router/go_router.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:ecommerece_app/core/widgets/safe_network_image.dart';

class CartItemWidget extends ConsumerWidget {
  final Map<String, dynamic> cartData;
  final String cartId;

  const CartItemWidget({
    super.key,
    required this.cartData,
    required this.cartId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatCurrency = NumberFormat('#,###');
    final productId = cartData['product_id'] as String?;
    final pricePointIndex = (cartData['pricePointIndex'] as int?) ?? 0;

    if (productId == null) {
      return const SizedBox.shrink();
    }

    final productAsync = ref.watch(productStreamProvider(productId));
    final isSub = ref.watch(isSubscribedProvider).value ?? false;

    return productAsync.when(
      data: (product) {
        if (product == null) {
          // Product was deleted, we should remove the cart item
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(cartControllerProvider.notifier).removeCartItem(cartId);
          });
          return const SizedBox.shrink();
        }

        // Calculate price based on subscription
        double price = 0.0;
        int quantity = 0;
        if (pricePointIndex < product.pricePoints.length) {
          final pp = product.pricePoints[pricePointIndex];
          price = pp.price.toDouble();
          if (!isSub) {
            price = price / 0.8;
          }
          quantity = pp.quantity;
        }

        final currentStock = product.stock;
        final isOutOfStock = quantity > currentStock;
        
        final cartPrice = cartData['price'] as int?;
        final currentLivePrice = price.round();
        final isPriceChanged = cartPrice != null && cartPrice != currentLivePrice;

        return InkWell(
          onTap: () async {
            String arrivalTime = await getArrivalDay(
              product.meridiem,
              product.baselineTime,
            );
            
            if (context.mounted) {
              context.pushNamed(
                Routes.itemDetailsScreen,
                extra: {
                  'product': product,
                  'arrivalDay': arrivalTime,
                  'isSub': isSub,
                },
              );
            }
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SafeNetworkImage(
                  url: product.imgUrl ?? '',
                  width: 106.w,
                  height: 106.h,
                  fit: BoxFit.cover,
                  placeholder: const ColoredBox(
                    color: Color(0xFFEEEEEE),
                  ),
                  errorWidget: const ColoredBox(
                    color: Color(0xFFEEEEEE),
                    child: Center(
                      child: Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: 10.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.sellerName,
                        style: TextStyles.abeezee14px400wP600,
                      ),
                      Text(
                        product.productName,
                        style: TextStyles.abeezee16px400wPblack,
                        maxLines: 2,
                        overflow: TextOverflow.visible,
                      ),
                      Text(
                        '수량 : ${quantity.toString()}  ',
                        style: TextStyles.abeezee14px400wP600,
                      ),
                      if (isOutOfStock)
                        Text(
                          '재고 부족 (남은 수량: $currentStock개)',
                          style: TextStyles.abeezee14px400wP600.copyWith(color: Colors.red),
                        ),
                      if (isPriceChanged)
                        Text(
                          '가격 변동됨 (이전: ${formatCurrency.format(cartPrice)} 원)',
                          style: TextStyles.abeezee14px400wP600.copyWith(color: Colors.orange),
                        ),
                      Text(
                        '${formatCurrency.format(price.round())} 원',
                        style: TextStyles.abeezee16px400wPblack,
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  ref.read(cartControllerProvider.notifier).removeCartItem(cartId);
                },
                icon: Icon(
                  Icons.close,
                  color: ColorsManager.primary600,
                  size: 18,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const ListTile(title: Text('로딩 중...')),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}
