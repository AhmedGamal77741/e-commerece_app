import 'dart:math';
import 'package:ecommerece_app/core/models/product_model.dart';
import 'package:ecommerece_app/features/shop/domain/shop_controller.dart';
import 'package:ecommerece_app/features/shop/widgets/shop_product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CategoryProductsScreen extends ConsumerStatefulWidget {
  final String categoryId;
  final String categoryName;
  final bool isSub;
  final ScrollController? scrollController;

  const CategoryProductsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.scrollController,
    this.isSub = false,
  });

  @override
  ConsumerState<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends ConsumerState<CategoryProductsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final Map<String, double> _productRandomWeight = {};

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final addressAsync = ref.watch(userDefaultAddressStreamProvider);
    final productsAsync = ref.watch(categoryProductsStreamProvider(widget.categoryId));

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: productsAsync.when(
        data: (products) {
          if (products.isEmpty) {
            return const Center(child: Text('아직 제품이 없습니다'));
          }

          // Fetch the user's mapped address payload
          final userAddressData = addressAsync.value;
          final userAddressMap = userAddressData != null 
              ? userAddressData['addressMap'] as Map<String, dynamic>?
              : null;
              
          final bool hasUserAddress = userAddressMap != null && userAddressMap.isNotEmpty;

          List<Product> sameRegion = [];
          List<Product> otherRegion = [];
          List<Product> soldOutList = [];

          for (var product in products) {
            if (hasUserAddress && !product.isDeliverableTo(userAddressMap)) {
              continue;
            }

            if (product.stock == 0) {
              soldOutList.add(product);
            } else {
              if (hasUserAddress) {
                sameRegion.add(product);
              } else {
                otherRegion.add(product);
              }
            }
          }

          final random = Random();
          sameRegion.sort((a, b) {
            final weightA = _productRandomWeight.putIfAbsent(a.productId, () => random.nextDouble());
            final weightB = _productRandomWeight.putIfAbsent(b.productId, () => random.nextDouble());
            return weightA.compareTo(weightB);
          });

          otherRegion.sort((a, b) {
            final weightA = _productRandomWeight.putIfAbsent(a.productId, () => random.nextDouble());
            final weightB = _productRandomWeight.putIfAbsent(b.productId, () => random.nextDouble());
            return weightA.compareTo(weightB);
          });

          final sortedProducts = [...sameRegion, ...otherRegion, ...soldOutList];

          return ListView.separated(
            controller: widget.scrollController,
            findChildIndexCallback: (Key key) {
              final valueKey = key as ValueKey<String>;
              final index = sortedProducts.indexWhere((p) => p.productId == valueKey.value);
              return index == -1 ? null : index;
            },
            separatorBuilder: (context, index) {
              if (index == sortedProducts.length - 1) {
                return const SizedBox.shrink();
              }
              return const Divider();
            },
            itemCount: sortedProducts.length,
            itemBuilder: (context, index) {
              return ShopProductCard(
                key: ValueKey(sortedProducts[index].productId),
                product: sortedProducts[index],
                isSub: widget.isSub,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('오류: $error')),
      ),
    );
  }
}
