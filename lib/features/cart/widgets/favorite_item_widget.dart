import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerece_app/core/helpers/basetime.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/features/auth/domain/auth_controller.dart';
import 'package:ecommerece_app/features/cart/domain/cart_controller.dart';
import 'package:ecommerece_app/features/shop/item_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class FavoriteItemWidget extends ConsumerWidget {
  final Map<String, dynamic> favoriteData;
  final String favoriteId;

  const FavoriteItemWidget({
    super.key,
    required this.favoriteData,
    required this.favoriteId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatCurrency = NumberFormat('#,###');
    final productId = favoriteData['product_id'] as String?;

    if (productId == null) {
      return const SizedBox.shrink();
    }

    final productAsync = ref.watch(productStreamProvider(productId));
    final isSub = ref.watch(isSubscribedProvider).value ?? false;

    return productAsync.when(
      data: (product) {
        if (product == null) {
          // Product was deleted, we should remove the favorite item
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(cartControllerProvider).removeFavItem(favoriteId);
          });
          return const SizedBox.shrink();
        }

        return InkWell(
          onTap: () async {
            String arrivalTime = await getArrivalDay(
              product.meridiem,
              product.baselineTime,
            );
            
            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ItemDetails(
                    product: product,
                    arrivalDay: arrivalTime,
                    isSub: isSub,
                  ),
                ),
              );
            }
          },
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 1.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: product.imgUrl ?? '',
                    width: 106.w,
                    height: 110.h,
                    fit: BoxFit.cover,
                    fadeInDuration: Duration.zero,
                    fadeOutDuration: Duration.zero,
                    placeholder: (context, url) => Container(
                      width: 106.w,
                      height: 110.h,
                      color: Colors.grey[200],
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 106.w,
                      height: 110.h,
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
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
                        isSub
                            ? '${formatCurrency.format(product.price)} 원'
                            : '${formatCurrency.format(product.price / 0.9)} 원',
                        style: TextStyles.abeezee16px400wPblack,
                      ),
                      Text(
                        '${product.arrivalDate ?? ''} ',
                        style: TextStyles.abeezee14px400wP600,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    ref.read(cartControllerProvider).removeFavItem(favoriteId);
                  },
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const ListTile(title: Text('로딩 중...')),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}
