import 'package:ecommerece_app/core/providers/firebase_providers.dart';
import 'package:ecommerece_app/features/cart/domain/cart_controller.dart';
import 'package:ecommerece_app/features/cart/widgets/favorite_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Center(child: Text('내 페이지 탭에서 회원가입 후 이용가능합니다.'));
        }

        final favoritesAsync = ref.watch(userFavoritesStreamProvider);

        return favoritesAsync.when(
          data: (favoritesDocs) {
            if (favoritesDocs.isEmpty) {
              return const Center(child: Text('찜한 상품이 없습니다.'));
            }

            return Padding(
              padding: EdgeInsets.only(left: 10.w, top: 12.h, bottom: 12.h),
              child: ListView.separated(
                separatorBuilder: (context, index) {
                  if (index == favoritesDocs.length - 1) {
                    return const SizedBox.shrink();
                  }
                  return const Divider();
                },
                itemCount: favoritesDocs.length,
                itemBuilder: (ctx, index) {
                  final favoriteDoc = favoritesDocs[index];
                  return FavoriteItemWidget(
                    favoriteData: favoriteDoc.data(),
                    favoriteId: favoriteDoc.id,
                  );
                },
              ),
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
