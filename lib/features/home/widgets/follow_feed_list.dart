import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ecommerece_app/features/home/widgets/post_item.dart';
import 'package:ecommerece_app/features/home/widgets/guest_preview.dart/guest_post_item.dart';

class UserCategoriesBar extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final String? selectedCategoryId;
  final Function(String) onCategorySelected;

  const UserCategoriesBar({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (categories.isEmpty) {
      return SizedBox(
        height: 50.h,
        child: Center(
          child: Text(
            '카테고리가 없습니다',
            style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }

    return Container(
      height: 50.h,
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: 16.w),
              _buildCategoryPill(theme, '뉴스', selectedCategoryId == null, () => onCategorySelected('')),
              ...categories.map((category) {
                final categoryName = category['name'] ?? '이름 없음';
                final isSelected = selectedCategoryId == category['id'];
                return Padding(
                  padding: EdgeInsets.only(left: 8.w),
                  child: _buildCategoryPill(theme, categoryName, isSelected, () => onCategorySelected(category['id'])),
                );
              }),
              SizedBox(width: 16.w),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPill(ThemeData theme, String categoryName, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF9E9E9E) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            categoryName,
            style: TextStyle(
              fontSize: 14.sp,
              color: isSelected ? const Color(0xFF424242) : const Color(0xFF9E9E9E),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class FollowingPostsList extends StatelessWidget {
  final List<Map<String, dynamic>> posts;
  final bool useGuestPostItem;
  final ScrollController? scrollController;

  const FollowingPostsList({
    super.key,
    required this.posts,
    this.useGuestPostItem = false,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.feed_outlined, size: 64, color: Color(0xFFE0E0E0)),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      cacheExtent: 500,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final postData = posts[index];
        final postId = postData['postId'] ?? postData['id'] ?? '';
        if (postId.isEmpty) return const SizedBox.shrink();

        return RepaintBoundary(
          key: ValueKey(postId),
          child: Column(
            children: [
              useGuestPostItem
                  ? GuestPostItem(postId: postId)
                  : PostItem(
                      postId: postId,
                      fromComments: false,
                    ),
              SizedBox(height: 10.h),
            ],
          ),
        );
      },
    );
  }
}
