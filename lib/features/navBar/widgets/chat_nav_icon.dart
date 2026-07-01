import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/nav_bar_providers.dart';

class ChatNavIcon extends ConsumerWidget {
  final bool isActive;
  const ChatNavIcon({super.key, required this.isActive});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasUnread = ref.watch(unreadChatRoomsProvider).value ?? false;
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Image.asset(
          isActive
              ? 'assets/chat_with_seller.png'
              : 'assets/chat_with_seller_grey.png',
          width: 30.r,
          height: 30.r,
          gaplessPlayback: true,
          cacheWidth: (30 * devicePixelRatio).toInt(),
        ),
        if (hasUnread)
          Positioned(
            left: -10.w,
            top: -5.h,
            child: Image.asset(
              'assets/notification.png',
              width: 18.w,
              height: 18.h,
              gaplessPlayback: true,
              cacheWidth: (18 * devicePixelRatio).toInt(),
            ),
          ),
      ],
    );
  }
}
