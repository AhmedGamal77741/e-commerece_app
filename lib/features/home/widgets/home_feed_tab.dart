import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerece_app/features/home/domain/feed_controller.dart';
import 'package:ecommerece_app/features/home/widgets/post_item.dart';
import 'package:ecommerece_app/features/home/widgets/guest_preview.dart/guest_post_item.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ecommerece_app/core/providers/firebase_providers.dart';

class HomeFeedTab extends ConsumerWidget {
  final ScrollController? scrollController;

  const HomeFeedTab({super.key, this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postIdsAsync = ref.watch(feedControllerProvider.select((asyncList) {
      return asyncList.whenData(
        (list) => list.map((p) => p['postId'] as String? ?? 'unknown').toList(),
      );
    }));
    final isGuest = ref.watch(authStateProvider).value == null;

    return postIdsAsync.when(
      data: (postIds) {
        if (postIds.isEmpty) {
          return const Center(child: Text('No posts available.'));
        }

        return ListView.builder(
          controller: scrollController,
          cacheExtent: 1200,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: false,
          itemCount: postIds.length,
          itemBuilder: (context, index) {
            final postId = postIds[index];

            return RepaintBoundary(
              key: ValueKey(postId),
              child: Padding(
                padding: EdgeInsets.only(bottom: isGuest ? 10.h : 16.h),
                child: isGuest
                    ? GuestPostItem(postId: postId)
                    : PostItem(postId: postId, fromComments: false),
              ),
            );
          },
        );
      },
      loading: () => const _FeedSkeleton(),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}

class _FeedSkeleton extends StatelessWidget {
  const _FeedSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              Expanded(
                child: Column(
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
                    SizedBox(height: 16.h),
                    Container(
                      width: double.infinity,
                      height: 200.h,
                      color: Colors.grey[300],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
