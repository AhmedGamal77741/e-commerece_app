import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerece_app/features/chat/services/contacts_service.dart';
import 'package:ecommerece_app/features/chat/widgets/chat_post_share.dart';
import 'package:ecommerece_app/features/home/comments.dart';
import 'package:ecommerece_app/features/home/profile_tab.dart';
import 'package:ecommerece_app/features/shop/item_details.dart';
import 'package:ecommerece_app/features/cart/domain/cart_controller.dart';

class CommentBubble extends ConsumerStatefulWidget {
  final Map<String, dynamic> item;
  final bool isMe;

  const CommentBubble({super.key, required this.item, required this.isMe});

  @override
  ConsumerState<CommentBubble> createState() => _CommentBubbleState();
}

class _CommentBubbleState extends ConsumerState<CommentBubble> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isMe = widget.isMe;
    final theme = Theme.of(context);
    
    double maxW = MediaQuery.of(context).size.width - 120.w;
    if (maxW > 400.w) maxW = 400.w;
    
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h, left: isMe ? 52.w : 0, right: isMe ? 0 : 52.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SafeArea(child: Scaffold(body: ProfileTab(userId: item['senderId'])))),
              ),
              child: Container(
                width: 40.w,
                height: 40.h,
                decoration: ShapeDecoration(
                  image: DecorationImage(
                    image: (item['senderImage'] as String).isNotEmpty
                        ? NetworkImage(item['senderImage'])
                        : const AssetImage('assets/avatar.png') as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                  shape: const OvalBorder(),
                ),
              ),
            ),
            SizedBox(width: 6.w),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: EdgeInsets.only(left: 4.w, bottom: 3.h),
                    child: FutureBuilder<String?>(
                      future: ContactService().getContactNickname(item['senderId']),
                      builder: (context, snapshot) {
                        final nickname = snapshot.data;
                        final display = nickname != null && nickname.isNotEmpty
                            ? '${item['senderName']} (@$nickname)'
                            : item['senderName'];
                        return Text(
                          display,
                          style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
                        );
                      },
                    ),
                  ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.all(Radius.circular(16.r)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if ((item['content'] as String).isNotEmpty)
                              Text(
                                item['content'],
                                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface, height: 1.4),
                              ),
                            if (item['postData'] != null) ...[
                              if ((item['content'] as String).isNotEmpty) SizedBox(height: 6.h),
                              ChatPostShareWidget(
                                type: 'post',
                                imageUrl: item['postData']['imgUrl'] ?? '',
                                authorName: item['postData']['userId'] ?? '',
                                postTitle: item['postData']['text'] ?? '',
                                onTap: () {
                                  if (item['postData']['postId'] != item['id'] || !item['isPost']) {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => Container(
                                        height: MediaQuery.of(context).size.height * 0.9,
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.surface,
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                          child: Comments(postId: item['postData']['postId']),
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                            if (item['productData'] != null) ...[
                              if ((item['content'] as String).isNotEmpty) SizedBox(height: 6.h),
                              ChatPostShareWidget(
                                type: 'product',
                                imageUrl: item['productData'].imgUrl ?? '',
                                postTitle: '${item['productData'].pricePoints[0].price} 원',
                                authorName: item['productData'].productName,
                                onTap: () async {
                                  final navigator = Navigator.of(context);
                                  bool isSub = await isUserSubscribed();
                                  navigator.push(
                                    MaterialPageRoute(
                                      builder: (_) => ItemDetails(
                                        product: item['productData'],
                                        isSub: isSub,
                                        arrivalDay: item['productData'].arrivalDate ?? '',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                            if (item['imageUrls'] != null && (item['imageUrls'] as List).isNotEmpty && item['postData'] == null) ...[
                              if ((item['content'] as String).isNotEmpty) SizedBox(height: 6.h),
                              if ((item['imageUrls'] as List).length == 1)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10.r),
                                  child: Container(
                                    constraints: BoxConstraints(maxWidth: maxW),
                                    child: Image.network((item['imageUrls'] as List).first, fit: BoxFit.cover),
                                  ),
                                )
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(top: 3.h, left: isMe ? 0 : 4.w, right: isMe ? 4.w : 0),
                  child: Text(
                    _formatTime(item['timestamp'] as DateTime),
                    style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
