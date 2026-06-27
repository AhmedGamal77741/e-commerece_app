import 'package:ecommerece_app/core/models/product_model.dart';
import 'package:ecommerece_app/features/chat/ui/chat_room_screen.dart';
import 'package:ecommerece_app/features/shop/domain/shop_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FloatingChatButton extends ConsumerWidget {
  final Product product;

  const FloatingChatButton({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned(
      right: 0.w,
      bottom: -10.h,
      child: IconButton(
        onPressed: () async {
          try {
            final returnList = await ref
                .read(shopControllerProvider.notifier)
                .createDirectChatRoomWithSeller(
                  product.deliveryManagerId.toString(),
                );
            if (!context.mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  chatRoomId: returnList[0],
                  chatRoomName: returnList[1],
                ),
              ),
            );
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e')),
            );
          }
        },
        icon: Image.asset(
          'assets/chat_with_seller.png',
          width: 50.w,
          height: 50.h,
        ),
      ),
    );
  }
}
