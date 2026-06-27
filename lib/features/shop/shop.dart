import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/features/auth/domain/auth_controller.dart';
import 'package:ecommerece_app/features/cart/cart.dart';
import 'package:ecommerece_app/features/address/ui/address_list_screen.dart';
import 'package:ecommerece_app/features/shop/domain/shop_controller.dart';
import 'package:ecommerece_app/features/shop/widgets/category_products_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class Shop extends ConsumerStatefulWidget {
  const Shop({super.key});

  @override
  ConsumerState<Shop> createState() => ShopState();
}

class ShopState extends ConsumerState<Shop> with TickerProviderStateMixin {
  TabController? _tabController;
  final Map<String, ScrollController> _scrollControllers = {};

  ScrollController _getScrollController(String categoryId) {
    return _scrollControllers.putIfAbsent(categoryId, () => ScrollController());
  }

  @override
  void dispose() {
    for (var controller in _scrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/003m.png'), context);
    precacheImage(const AssetImage('assets/order_history.png'), context);
    precacheImage(const AssetImage('assets/010no_cropped.png'), context);
  }

  void resetToFirstCategory() {
    if (_tabController != null) {
      _tabController!.animateTo(0);
    }
    if (_scrollControllers.isNotEmpty) {
      final firstController = _scrollControllers.values.first;
      if (firstController.hasClients) {
        firstController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final userAddressAsync = ref.watch(userDefaultAddressStreamProvider);
    final isSub = ref.watch(isSubscribedProvider).value ?? false;

    return switch (categoriesAsync) {
      AsyncData(:final value) => _buildShopContent(value, userAddressAsync, isSub),
      AsyncError(:final error) => Scaffold(
          appBar: AppBar(title: const Text('Shop')),
          body: Center(child: Text('Error: $error')),
        ),
      _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
    };
  }

  Widget _buildShopContent(
    List<Map<String, dynamic>> categories,
    AsyncValue<Map<String, dynamic>?> userAddressAsync,
    bool isSub,
  ) {
    if (categories.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Shop')),
        body: const Center(child: Text('No categories available')),
      );
    }

    return DefaultTabController(
      key: ValueKey(categories.map((c) => c['id']).join(',')),
      length: categories.length,
      initialIndex: 0,
      child: Builder(
        builder: (context) {
          _tabController = DefaultTabController.of(context);

          return Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const Cart()));
              },
              elevation: 0,
              backgroundColor: Colors.black,
              shape: const CircleBorder(),
              child: ImageIcon(
                const AssetImage('assets/003m.png'),
                color: Colors.white,
                size: 40.r,
              ),
            ),
            appBar: AppBar(
              toolbarHeight: 0,
              elevation: 0,
              title: const Text(''),
              centerTitle: false,
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(100.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: 8.w),
                          child: TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0),
                              minimumSize: const Size(0, 0),
                              maximumSize: Size(200.w, 80.h),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const AddressListScreen()),
                              );
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: _buildAddressText(userAddressAsync),
                                ),
                                SizedBox(width: 6.w),
                                const Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.black,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () {
                            context.go(Routes.reviewScreen);
                          },
                          child: Image.asset(
                            'assets/order_history.png',
                            color: Colors.black,
                            width: 28.w,
                            height: 28.h,
                          ),
                        ),
                        horizontalSpace(12),
                        InkWell(
                          onTap: () {
                            context.go(Routes.shopSearchScreen);
                          },
                          child: Image.asset(
                            'assets/010no_cropped.png',
                            color: Colors.black,
                            width: 22.w,
                            height: 28.h,
                          ),
                        ),
                        horizontalSpace(12),
                      ],
                    ),
                    TabBar(
                      tabAlignment: TabAlignment.start,
                      dragStartBehavior: DragStartBehavior.start,
                      padding: EdgeInsets.zero,
                      labelPadding: EdgeInsets.symmetric(horizontal: 16.w),
                      labelStyle: TextStyle(
                        fontSize: 16.sp,
                        decoration: TextDecoration.none,
                        fontFamily: 'NotoSans',
                        fontStyle: FontStyle.normal,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0,
                        color: ColorsManager.primaryblack,
                      ),
                      unselectedLabelColor: ColorsManager.primary600,
                      indicatorSize: TabBarIndicatorSize.label,
                      indicatorColor: ColorsManager.primaryblack,
                      isScrollable: true,
                      tabs: categories
                          .map<Widget>((category) => Tab(text: category['name'], height: 45.h))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
            body: Padding(
              padding: EdgeInsets.only(right: 8.w, top: 15.h, bottom: 4.h),
              child: TabBarView(
                children: categories
                    .map<Widget>((category) => CategoryProductsScreen(
                          categoryId: category['id'],
                          categoryName: category['name'],
                          isSub: isSub,
                          scrollController: _getScrollController(category['id']),
                        ))
                    .toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddressText(AsyncValue<Map<String, dynamic>?> userAddressAsync) {
    final textStyle = TextStyle(
      color: Colors.black,
      fontSize: 16.sp,
      fontWeight: FontWeight.w500,
    );

    return switch (userAddressAsync) {
      AsyncData(:final value) => Builder(builder: (context) {
          String displayName = '배송지 선택';
          if (value != null) {
            final basic = value['address'] as String? ?? '';
            final detail = value['detailAddress'] as String? ?? '';
            displayName = detail.isEmpty
                ? (basic.isEmpty ? '배송지 선택' : basic)
                : '$basic $detail';
          }
          return Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle,
          );
        }),
      AsyncError() => Text('배송지 선택', style: textStyle),
      _ => Text('로딩 중...', style: textStyle),
    };
  }
}
