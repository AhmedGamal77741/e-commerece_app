import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerece_app/features/home/domain/feed_controller.dart';
import 'package:ecommerece_app/features/home/widgets/post_item.dart';
import 'package:ecommerece_app/features/home/widgets/guest_preview.dart/guest_post_item.dart';
import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ecommerece_app/core/providers/firebase_providers.dart';

class HomeFeedTab extends ConsumerWidget {
  final ScrollController? scrollController;

  const HomeFeedTab({super.key, this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(feedControllerProvider);
    final authState = ref.watch(authStateProvider);
    final firebaseUser = authState.value;

    return feedAsync.when(
      data: (posts) {
        if (posts.isEmpty) {
          return const Center(child: Text('No posts available.'));
        }

        return NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            final notifier = ref.read(feedControllerProvider.notifier);
            if (notifier.hasMore && scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
              notifier.fetchNextPage();
            }
            return false;
          },
          child: ListView.builder(
            controller: scrollController,
            cacheExtent: 500,
            itemCount: posts.length + (firebaseUser != null ? 1 : 0),
            itemBuilder: (context, index) {
              if (firebaseUser != null && index == 0) {
                return const SizedBox.shrink();
              }
  
              final postIndex = firebaseUser != null ? index - 1 : index;
              final post = posts[postIndex];
              final postId = post['postId'] ?? 'unknown';
  
              if (firebaseUser == null) {
                return RepaintBoundary(
                  key: ValueKey(postId),
                  child: Column(
                    children: [
                      GuestPostItem(post: post),
                      verticalSpace(10),
                    ],
                  ),
                );
              }
  
              return RepaintBoundary(
                key: ValueKey(postId),
                child: Column(
                  children: [
                    PostItem(
                      postId: postId,
                      fromComments: false,
                      postData: post,
                    ),
                    SizedBox(height: 16.h),
                  ],
                ),
              );
            },
          ),
        );
      },
      loading:
          () => _PulsingSkeleton(
            child: ListView.builder(
              itemCount: 3,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 16.h,
                    horizontal: 16.w,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40.w,
                            height: 40.w,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 120.w,
                                height: 14.h,
                                color: Colors.grey[300],
                              ),
                              SizedBox(height: 6.h),
                              Container(
                                width: 80.w,
                                height: 10.h,
                                color: Colors.grey[300],
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      Container(
                        width: double.infinity,
                        height: 300.h,
                        color: Colors.grey[300],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}

class _PulsingSkeleton extends StatefulWidget {
  final Widget child;
  const _PulsingSkeleton({required this.child});

  @override
  State<_PulsingSkeleton> createState() => _PulsingSkeletonState();
}

class _PulsingSkeletonState extends State<_PulsingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 0.85).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: widget.child,
    );
  }
}
