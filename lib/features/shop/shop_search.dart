import 'package:ecommerece_app/core/helpers/basetime.dart';
import 'package:ecommerece_app/core/models/product_model.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/features/shop/item_details.dart';
import 'package:ecommerece_app/features/shop/domain/shop_controller.dart';
import 'package:ecommerece_app/core/providers/firebase_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ShopSearch extends ConsumerStatefulWidget {
  const ShopSearch({super.key});

  @override
  ConsumerState<ShopSearch> createState() => _ShopSearchState();
}

class _ShopSearchState extends ConsumerState<ShopSearch> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  final formatCurrency = NumberFormat('#,###');

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(categoryProductsStreamProvider('all'));
    final userProfileAsync = ref.watch(userProfileStreamProvider);

    bool isSub = false;
    userProfileAsync.whenData((profile) {
      if (profile != null && profile.containsKey('isSub')) {
        isSub = profile['isSub'] == true;
      }
    });

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 40.w,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: ColorsManager.primary600),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: '검색...',
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 5.h,
            ),
            border: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
              borderRadius: BorderRadius.zero,
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
              borderRadius: BorderRadius.zero,
            ),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
              borderRadius: BorderRadius.zero,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const ImageIcon(AssetImage('assets/Frame 4.png')),
            iconSize: 30.sp,
            onPressed: () {},
          ),
        ],
      ),
      body: productsAsync.when(
        data: (allProducts) {
          final filteredProducts = _searchQuery.isEmpty
              ? allProducts
              : allProducts
                  .where((p) =>
                      p.productName.toLowerCase().contains(_searchQuery))
                  .toList();

          if (filteredProducts.isEmpty && _searchQuery.isNotEmpty) {
            return const Center(child: Text('결과가 없습니다'));
          }

          if (filteredProducts.isEmpty) {
            return const SizedBox.shrink();
          }

          return ListView.builder(
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) {
              final product = filteredProducts[index];
              return ListTile(
                title: Text(product.productName),
                subtitle: isSub
                    ? Text('${formatCurrency.format(product.price)} 원')
                    : Text('${formatCurrency.format(product.price / 0.8)} 원'),
                leading: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: product.imgUrl ?? '',
                      width: 50.w,
                      height: 50.h,
                      fit: BoxFit.cover,
                      fadeInDuration: Duration.zero,
                      fadeOutDuration: Duration.zero,
                      placeholder: (context, url) => Container(
                        width: 50.w,
                        height: 50.h,
                        color: Colors.grey[200],
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 50.w,
                        height: 50.h,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    if (product.stock == 0)
                      Positioned.fill(
                        child: Container(
                          color: Colors.transparent,
                          child: Center(
                            child: Image.asset(
                              'assets/sold_out.png',
                              fit: BoxFit.contain,
                              cacheWidth: 100,
                              cacheHeight: 100,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
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
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.black)),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
