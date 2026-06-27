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
        
        return ListView.builder(
          shrinkWrap: true,
          controller: scrollController,
          itemCount: posts.length + (firebaseUser != null ? 1 : 0),
          itemBuilder: (context, index) {
            if (firebaseUser != null && index == 0) {
              return const SizedBox.shrink();
            }
            
            final postIndex = firebaseUser != null ? index - 1 : index;
            final post = posts[postIndex];
            final postId = post['postId'] ?? 'unknown';

            if (firebaseUser == null) {
              return Column(
                key: ValueKey(postId),
                children: [
                  GuestPostItem(post: post),
                  verticalSpace(10),
                ],
              );
            }

            return Column(
              key: ValueKey(postId),
              children: [
                PostItem(
                  postId: postId,
                  fromComments: false,
                ),
                SizedBox(height: 16.h),
              ],
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}
