import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerece_app/features/chat/widgets/chat_post_share.dart';
import 'package:ecommerece_app/features/home/comments.dart';
import 'package:go_router/go_router.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/features/cart/domain/cart_controller.dart';
import 'package:ecommerece_app/core/widgets/safe_network_image.dart';
import 'package:ecommerece_app/features/home/widgets/post_item_components/natural_aspect_page_view.dart';
import 'package:ecommerece_app/core/widgets/user_name_header.dart';
import 'package:ecommerece_app/core/widgets/full_screen_image_viewer.dart';

class CommentBubble extends ConsumerStatefulWidget {
  final Map<String, dynamic> item;
  final bool isMe;
  final bool showAvatarAndName;
  final bool showTime;

  const CommentBubble({
    super.key,
    required this.item,
    required this.isMe,
    this.showAvatarAndName = true,
    this.showTime = true,
  });

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
    final showAvatarAndName = widget.showAvatarAndName;
    final showTime = widget.showTime;
    final theme = Theme.of(context);

    double maxW = MediaQuery.of(context).size.width - 120.w;
    if (maxW > 400.w) maxW = 400.w;

    return Padding(
      padding: EdgeInsets.only(bottom: 4.h, left: isMe ? 52.w : 0, right: isMe ? 0 : 52.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            if (showAvatarAndName) ...[
              GestureDetector(
                onTap: () => context.pushNamed(Routes.profileTabScreen, extra: {'userId': item['senderId']}),
                child: Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: ShapeDecoration(
                    image: DecorationImage(
                      image: (item['senderImage'] as String).isNotEmpty
                          ? safeNetworkImageProvider(item['senderImage'])
                          : const AssetImage('assets/avatar.png') as ImageProvider,
                      fit: BoxFit.cover,
                    ),
                    shape: const OvalBorder(),
                  ),
                ),
              ),
              SizedBox(width: 6.w),
            ] else
              SizedBox(width: 46.w),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe && showAvatarAndName)
                  Padding(
                    padding: EdgeInsets.only(left: 4.w, bottom: 3.h),
                    child: UserNameHeader(
                      userId: item['senderId'] ?? '',
                      accountName: item['senderName'] ?? '',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      textColor: theme.colorScheme.onSurfaceVariant,
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
                          color: const Color(0xFFEEEEEE),
                          borderRadius: BorderRadius.all(Radius.circular(16.r)),
                          border: Border.all(color: const Color(0xFFE0E0E0), width: 1.0),
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
                                imageUrl: getPostImageUrl(item['postData'] as Map<String, dynamic>?),
                                authorName: (item['postData']['authorName'] as String?)?.isNotEmpty == true
                                    ? item['postData']['authorName'] as String
                                    : (item['postData']['userId'] as String? ?? ''),
                                postTitle: item['postData']['text'] as String? ?? '',
                                onTap: () {
                                  final postId = item['postData']['postId'] as String? ?? item['postData']['id'] as String? ?? '';
                                  if (postId.isEmpty) return;
                                  if (postId != item['id'] || !item['isPost']) {
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
                                          child: Comments(postId: postId),
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
                                  bool isSub = await isUserSubscribed();
                                  if (!context.mounted) return;
                                  final product = item['productData'];
                                  context.pushNamed(
                                    'productDetails',
                                    pathParameters: {'productId': product.productId},
                                    extra: {
                                      'product': product,
                                      'isSub': isSub,
                                      'arrivalDay': product.arrivalDate ?? '',
                                    },
                                  );
                                },
                              ),
                            ],
                            if (item['imageUrls'] != null && (item['imageUrls'] as List).isNotEmpty && item['postData'] == null) ...[
                              if ((item['content'] as String).isNotEmpty) SizedBox(height: 6.h),
                              GestureDetector(
                                onTap: () {
                                  final List rawUrls = item['imageUrls'] as List;
                                  final List<String> urls = rawUrls.map((e) => e.toString()).toList();
                                  final int currentIdx = _pageController.hasClients ? (_pageController.page?.round() ?? 0) : 0;
                                  FullScreenImageViewer.open(context, imageUrls: urls, initialIndex: currentIdx);
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10.r),
                                  child: SizedBox(
                                    width: maxW,
                                    child: NaturalAspectPageView(
                                      imgUrls: item['imageUrls'] as List,
                                      pageController: _pageController,
                                      explicitWidth: maxW,
                                      imageRatios: item['imageRatios'] as Map?,
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (showTime)
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
