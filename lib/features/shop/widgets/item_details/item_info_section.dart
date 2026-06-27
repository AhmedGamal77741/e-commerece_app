import 'package:ecommerece_app/core/models/product_model.dart';
import 'package:ecommerece_app/core/providers/firebase_providers.dart';
import 'package:ecommerece_app/features/home/widgets/share_dialog.dart';
import 'package:ecommerece_app/features/shop/domain/shop_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ItemInfoSection extends ConsumerStatefulWidget {
  final Product product;

  const ItemInfoSection({
    super.key,
    required this.product,
  });

  @override
  ConsumerState<ItemInfoSection> createState() => _ItemInfoSectionState();
}

class _ItemInfoSectionState extends ConsumerState<ItemInfoSection> {
  late bool liked = false;

  @override
  void initState() {
    super.initState();
    final currentUser = ref.read(authStateProvider).value;
    if (currentUser != null) {
      liked = widget.product.favBy.contains(currentUser.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authStateProvider).value;
    final isLoggedIn = currentUser != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 14.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.sellerName,
                  style: TextStyle(
                    color: const Color(0xFF121212),
                    fontSize: 14.sp,
                    fontFamily: 'NotoSans',
                    fontWeight: FontWeight.w400,
                    height: 1.40,
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  widget.product.productName,
                  style: TextStyle(
                    color: const Color(0xFF121212),
                    fontSize: 16.sp,
                    fontFamily: 'NotoSans',
                    fontWeight: FontWeight.w400,
                    height: 1.40,
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  widget.product.stock == 0
                      ? '품절'
                      : widget.product.arrivalDate ?? '',
                  style: TextStyle(
                    color: const Color(0xFF747474),
                    fontSize: 14.sp,
                    fontFamily: 'NotoSans',
                    fontWeight: FontWeight.w400,
                    height: 1.40,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  final url =
                      'https://www.pang2chocolate.com/product/${widget.product.productId}';
                  showShareDialog(
                    context,
                    'product',
                    url,
                    widget.product.productId,
                    widget.product.productName,
                    widget.product.imgUrl.toString(),
                    widget.product.toMap(),
                  );
                },
                icon: ImageIcon(
                  const AssetImage('assets/grey_006m.png'),
                  size: 32.sp,
                  color: (liked && isLoggedIn) ? Colors.black : Colors.grey,
                ),
              ),
              IconButton(
                onPressed: !isLoggedIn
                    ? null
                    : () async {
                        final wasLiked = liked;
                        setState(() => liked = !liked);

                        try {
                          if (wasLiked) {
                            await ref
                                .read(shopControllerProvider.notifier)
                                .removeFavItemByProductId(
                                  widget.product.productId,
                                );
                          } else {
                            await ref
                                .read(shopControllerProvider.notifier)
                                .addFavItem(widget.product.productId);
                          }
                        } catch (e) {
                          setState(() => liked = wasLiked);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  '요청을 처리하는 동안 오류가 발생했습니다. 다시 시도해주세요.',
                                ),
                              ),
                            );
                          }
                        }
                      },
                icon: ImageIcon(
                  (liked && isLoggedIn)
                      ? const AssetImage('assets/black_007m.png')
                      : const AssetImage('assets/grey_007m.png'),
                  size: 32.sp,
                  color: (liked && isLoggedIn) ? Colors.black : Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
