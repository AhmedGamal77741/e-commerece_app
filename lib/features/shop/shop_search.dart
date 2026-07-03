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

  bool _isSameRegion(
    Map<String, dynamic>? userAddress,
    Map<String, dynamic>? productAddress,
  ) {
    if (userAddress == null || productAddress == null) return false;
    final userRegion1 =
        userAddress['road_address']?['region_1depth_name'] ??
        userAddress['address']?['region_1depth_name'] ??
        userAddress['region_1depth_name'];
    final userRegion2 =
        userAddress['road_address']?['region_2depth_name'] ??
        userAddress['address']?['region_2depth_name'] ??
        userAddress['region_2depth_name'];
    final productRegion1 =
        productAddress['road_address']?['region_1depth_name'] ??
        productAddress['address']?['region_1depth_name'] ??
        productAddress['region_1depth_name'];
    final productRegion2 =
        productAddress['road_address']?['region_2depth_name'] ??
        productAddress['address']?['region_2depth_name'] ??
        productAddress['region_2depth_name'];
    if (userRegion1 == null || productRegion1 == null) return false;
    if (userRegion1 != productRegion1) return false;
    if (userRegion2 != null &&
        userRegion2.isNotEmpty &&
        productRegion2 != null &&
        productRegion2.isNotEmpty) {
      if (userRegion2 != productRegion2) return false;
    }
    return true;
  }

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
      if (hasUserAddress && !_isSameRegion(userAddress, product.address)) {
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
