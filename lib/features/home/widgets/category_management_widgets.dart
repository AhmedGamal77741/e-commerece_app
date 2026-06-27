import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerece_app/features/home/domain/add_post_notifier.dart';

class CategoryBanner extends ConsumerWidget {
  const CategoryBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addPostNotifierProvider);
    if (!state.isArrangeMode && !state.isDeleteMode) return const SizedBox.shrink();

    final isArrangeMode = state.isArrangeMode;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isArrangeMode ? Colors.grey[100] : Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isArrangeMode ? Colors.grey[300]! : Colors.red[200]!,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isArrangeMode ? Icons.swap_vert : Icons.delete_outline,
                size: 18,
                color: isArrangeMode ? Colors.black : Colors.red[700],
              ),
              SizedBox(width: 8.w),
              Text(
                isArrangeMode ? '카테고리를 드래그하여 정렬하세요' : '삭제할 카테고리의 X를 클릭하세요',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isArrangeMode ? Colors.black : Colors.red[900],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: () {
              ref.read(addPostNotifierProvider.notifier).exitModes();
            },
            style: TextButton.styleFrom(
              backgroundColor: isArrangeMode ? Colors.black : Colors.red[700],
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              '완료',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryPill extends ConsumerWidget {
  final String categoryName;
  final String categoryId;
  final bool isSelected;
  final bool isInDeleteMode;
  final bool isInEditMode;
  final bool isArrangeMode;

  const CategoryPill({
    super.key,
    required this.categoryName,
    required this.categoryId,
    required this.isSelected,
    required this.isInDeleteMode,
    required this.isInEditMode,
    required this.isArrangeMode,
  });

  void _showEditCategoryDialog(BuildContext context, WidgetRef ref) {
    final textEditingController = TextEditingController(text: categoryName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text('카테고리 이름 변경', style: Theme.of(context).textTheme.titleLarge),
        content: TextField(
          controller: textEditingController,
          decoration: const InputDecoration(hintText: '카테고리 이름'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          ),
          TextButton(
            onPressed: () {
              ref.read(addPostNotifierProvider.notifier).updateCategoryName(categoryId, textEditingController.text);
              Navigator.pop(context);
            },
            child: Text('저장', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: isInDeleteMode
          ? null
          : isInEditMode
              ? () => _showEditCategoryDialog(context, ref)
              : () {
                  ref.read(addPostNotifierProvider.notifier).selectCategory(categoryId);
                },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.surfaceContainerHighest,
          border: Border.all(
            color: isSelected ? Colors.transparent : Theme.of(context).colorScheme.outlineVariant,
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isArrangeMode) ...[
              Icon(Icons.drag_handle, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
              SizedBox(width: 4.w),
            ],
            Text(
              categoryName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSelected ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (isInDeleteMode) ...[
              SizedBox(width: 6.w),
              GestureDetector(
                onTap: () => ref.read(addPostNotifierProvider.notifier).deleteCategory(categoryId),
                child: Icon(Icons.close, size: 14, color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (isInEditMode) ...[
              SizedBox(width: 6.w),
              Icon(Icons.edit, size: 14, color: Colors.orange), // Assuming orange is a brand accent not in colorScheme directly
            ],
          ],
        ),
      ),
    );
  }
}

class CategoryList extends ConsumerWidget {
  const CategoryList({super.key});

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
    final textEditingController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text('새 카테고리', style: Theme.of(context).textTheme.titleLarge),
        content: TextField(
          controller: textEditingController,
          decoration: const InputDecoration(hintText: '카테고리 이름'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          ),
          TextButton(
            onPressed: () {
              ref.read(addPostNotifierProvider.notifier).addCategory(textEditingController.text);
              Navigator.pop(context);
            },
            child: Text('추가', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          ),
        ],
      ),
    );
  }

  void _showCategoryMenu(BuildContext context, WidgetRef ref, AddPostState state) {
    showMenu(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width - 50,
        120.h,
        16.w,
        0,
      ),
      items: [
        PopupMenuItem(
          value: 'add',
          child: Text('추가', style: Theme.of(context).textTheme.bodyMedium),
        ),
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Text('이름 변경', style: Theme.of(context).textTheme.bodyMedium),
              if (state.isEditMode) ...[
                SizedBox(width: 8.w),
                const Icon(Icons.check, size: 16, color: Colors.green),
              ],
            ],
          ),
        ),
        PopupMenuItem(
          value: 'arrange',
          child: Row(
            children: [
              Text('정렬', style: Theme.of(context).textTheme.bodyMedium),
              if (state.isArrangeMode) ...[
                SizedBox(width: 8.w),
                const Icon(Icons.check, size: 16, color: Colors.green),
              ],
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Text('삭제', style: Theme.of(context).textTheme.bodyMedium),
              if (state.isDeleteMode) ...[
                SizedBox(width: 8.w),
                const Icon(Icons.check, size: 16, color: Colors.green),
              ],
            ],
          ),
        ),
      ],
    ).then((value) {
      if (!context.mounted) return;
      if (value == 'add') {
        _showAddCategoryDialog(context, ref);
      } else if (value == 'edit') {
        ref.read(addPostNotifierProvider.notifier).toggleEditMode();
      } else if (value == 'arrange') {
        ref.read(addPostNotifierProvider.notifier).toggleArrangeMode();
      } else if (value == 'delete') {
        ref.read(addPostNotifierProvider.notifier).toggleDeleteMode();
      }
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addPostNotifierProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: SizedBox(
            height: 35.h,
            child: state.categories.isEmpty
                ? Center(
                    child: Text(
                      '카테고리를 추가해주세요',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: state.categories.length,
                    itemBuilder: (context, index) {
                      final category = state.categories[index];
                      final isSelected = state.selectedCategoryId == category['id'];

                      final pill = CategoryPill(
                        categoryName: category['name'],
                        categoryId: category['id'],
                        isSelected: isSelected,
                        isInDeleteMode: state.isDeleteMode,
                        isInEditMode: state.isEditMode,
                        isArrangeMode: state.isArrangeMode,
                      );

                      return Padding(
                        padding: EdgeInsets.only(right: 8.w),
                        child: state.isArrangeMode
                            ? Draggable<int>(
                                data: index,
                                feedback: Material(color: Colors.transparent, child: pill),
                                childWhenDragging: Opacity(opacity: 0.5, child: pill),
                                child: DragTarget<int>(
                                  onAcceptWithDetails: (details) {
                                    final draggedIndex = details.data;
                                    final newCategories = List<Map<String, dynamic>>.from(state.categories);
                                    final draggedCategory = newCategories.removeAt(draggedIndex);
                                    newCategories.insert(index, draggedCategory);
                                    ref.read(addPostNotifierProvider.notifier).updateCategoryOrder(newCategories);
                                  },
                                  builder: (context, candidateData, rejectedData) => pill,
                                ),
                              )
                            : pill,
                      );
                    },
                  ),
          ),
        ),
        IconButton(
          icon: CircleAvatar(
            radius: 15.r,
            backgroundColor: Colors.transparent,
            backgroundImage: const AssetImage('assets/settings.png'),
          ),
          onPressed: () => _showCategoryMenu(context, ref, state),
        ),
      ],
    );
  }
}
