import 'package:ecommerece_app/core/models/product_model.dart';
import 'package:ecommerece_app/features/shop/domain/shop_controller.dart';
import 'package:ecommerece_app/features/auth/domain/auth_controller.dart';
import 'package:ecommerece_app/features/home/domain/search_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ecommerece_app/features/shop/widgets/shop_product_card.dart';

class ShopSearch extends ConsumerWidget {
  const ShopSearch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(categoryProductsStreamProvider('all'));
    final isSub = ref.watch(isSubscribedProvider).value ?? false;
    final query = ref.watch(searchNotifierProvider).value?.query ?? '';
    final userAddressAsync = ref.watch(userDefaultAddressStreamProvider);
    final userAddressRaw = userAddressAsync.value?['addressMap'];
    final userAddress = userAddressRaw is Map
        ? Map<String, dynamic>.from(userAddressRaw)
        : null;

    return switch (productsAsync) {
      AsyncData(:final value) => _buildSearchResults(
        value,
        isSub,
        query,
        userAddress,
      ),
      AsyncError(:final error) => Center(child: Text('Error: $error')),
      _ => const Center(child: CircularProgressIndicator(color: Colors.black)),
    };
  }

  Widget _buildSearchResults(
    List<Product> allProducts,
    bool isSub,
    String query,
    Map<String, dynamic>? userAddress,
  ) {
    if (query.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final filteredProducts =
        allProducts
            .where(
                (p) => p.productName.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();

    if (filteredProducts.isEmpty) {
      return const Center(child: Text('결과가 없습니다'));
    }

    List<Product> sameRegion = [];
    List<Product> otherRegion = [];
    List<Product> soldOutList = [];

    final bool hasUserAddress = userAddress != null && userAddress.isNotEmpty;

    for (var product in filteredProducts) {
      if (hasUserAddress && !product.isDeliverableTo(userAddress)) {
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

    final sortedProducts = [...sameRegion, ...otherRegion, ...soldOutList];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: ListView.separated(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        findItemIndexCallback: (Key key) {
          final valueKey = key as ValueKey<String>;
          final index = sortedProducts.indexWhere(
            (p) => p.productId == valueKey.value,
          );
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
            isSub: isSub,
          );
        },
      ),
    );
  }
}
