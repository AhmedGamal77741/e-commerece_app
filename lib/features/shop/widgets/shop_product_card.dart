import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/models/product_model.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ecommerece_app/core/widgets/safe_network_image.dart';

class ShopProductCard extends StatelessWidget {
  final Product product;
  final bool isSub;

  const ShopProductCard({
    super.key,
    required this.product,
    required this.isSub,
  });

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat('#,###');
    
    return InkWell(
      onTap: () {
        GoRouter.of(context).pushNamed(
          'productDetails',
          pathParameters: {
            'productId': product.productId.toString(),
          },
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 1.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: product.imgUrl != null && product.imgUrl!.isNotEmpty
                      ? SafeNetworkImage(
                          url: product.imgUrl!,
                          width: 106.w,
                          height: 106.h,
                          fit: BoxFit.cover,
                          placeholder: Container(
                            width: 106.w,
                            height: 106.h,
                            color: Colors.grey[200],
                          ),
                          errorWidget: Container(
                            width: 106.w,
                            height: 106.h,
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(Icons.broken_image, color: Colors.grey),
                            ),
                          ),
                        )
                      : Container(
                          width: 106.w,
                          height: 106.h,
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.image_not_supported, color: Colors.grey),
                          ),
                        ),
                ),
                if (product.stock == 0)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        color: Colors.transparent,
                        child: const Center(
                          child: Image(
                            image: ResizeImage(
                              AssetImage('assets/sold_out.png'),
                              width: 200,
                              height: 200,
                            ),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
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
                  verticalSpace(5),
                  Text(
                    product.productName,
                    style: TextStyles.abeezee16px400wPblack,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    isSub
                        ? '${formatCurrency.format(product.price)} 원'
                        : '${formatCurrency.format(product.price / 0.8)} 원',
                    style: TextStyles.abeezee16px400wPblack,
                  ),
                  verticalSpace(2),
                  Text(
                    '${product.arrivalDate ?? ''} ',
                    style: TextStyles.abeezee14px400wP600,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
