import 'package:ecommerece_app/core/widgets/tab_app_bar.dart';
import 'package:ecommerece_app/features/cart/favorites.dart';
import 'package:ecommerece_app/features/cart/shopping_cart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Cart extends ConsumerWidget {
  const Cart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: TabAppBar(
          imgUrl: '003m.png',
          firstTab: '장바구니',
          secondTab: '즐겨찾기',
        ),
        body: SafeArea(
          bottom: true,
          child: TabBarView(children: [ShoppingCart(), FavoritesScreen()]),
        ),
      ),
    );
  }
}
