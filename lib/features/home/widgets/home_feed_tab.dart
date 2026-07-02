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
    final postIdsAsync = ref.watch(feedControllerProvider.select((asyncList) {
      return asyncList.whenData((list) => list.map((p) => p['postId'] as String? ?? 'unknown').toList());
    }));
    final authState = ref.watch(authStateProvider);
    final firebaseUser = authState.value;

    return postIdsAsync.when(
      data: (postIds) {
        if (postIds.isEmpty) {
          return const Center(child: Text('No posts available.'));
        }

        return ListView.builder(
          controller: scrollController,
          cacheExtent: 500,
          itemCount: postIds.length,
          itemBuilder: (context, index) {
            final postId = postIds[index];

            if (firebaseUser == null) {
              return RepaintBoundary(
                key: ValueKey(postId),
                child: Column(
                  children: [
                    GuestPostItem(postId: postId),
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
                  ),
                  SizedBox(height: 16.h),
                ],
              ),
            );
          },
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

class _PulsingSkeleton extends StatelessWidget {
  final Widget child;
  const _PulsingSkeleton({required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
