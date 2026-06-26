import 'package:ecommerece_app/features/auth/domain/auth_controller.dart';
import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/providers/firebase_providers.dart';
import 'package:ecommerece_app/features/cart/domain/cart_controller.dart';
import 'package:ecommerece_app/features/cart/widgets/cart_checkout_bar.dart';
import 'package:ecommerece_app/features/cart/widgets/cart_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ShoppingCart extends ConsumerWidget {
  const ShoppingCart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Center(child: Text('내 페이지 탭에서 회원가입 후 이용가능합니다.'));
        }

        final cartDocsAsync = ref.watch(userCartStreamProvider);

        return cartDocsAsync.when(
          data: (cartDocs) {
            return Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                    child: ListView.separated(
                      separatorBuilder: (context, index) {
                        if (index == cartDocs.length - 1) return const SizedBox.shrink();
                        return const Divider();
                      },
                      itemCount: cartDocs.length,
                      itemBuilder: (ctx, index) {
                        final cartDoc = cartDocs[index];
                        return CartItemWidget(
                          cartData: cartDoc.data(),
                          cartId: cartDoc.id,
                        );
                      },
                    ),
                  ),
                ),
                if (cartDocs.isNotEmpty) const CartCheckoutBar(),
                verticalSpace(25),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}
