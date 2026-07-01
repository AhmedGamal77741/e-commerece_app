import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/features/home/domain/follow_feed_notifier.dart';
import 'package:ecommerece_app/features/home/domain/feed_controller.dart';
import 'package:ecommerece_app/features/home/widgets/following_users_list.dart';
import 'package:ecommerece_app/features/home/widgets/follow_feed_list.dart';

class FollowingTab extends ConsumerStatefulWidget {
  final String? preselectedUser;
  final ScrollController? scrollController;

  const FollowingTab({super.key, this.preselectedUser, this.scrollController});

  @override
  ConsumerState<FollowingTab> createState() => _FollowingTabState();
}

class _FollowingTabState extends ConsumerState<FollowingTab>
    with AutomaticKeepAliveClientMixin {
  late ScrollController _scrollController;
  final ValueNotifier<String?> _selectedUserId = ValueNotifier(null);
  final ValueNotifier<String?> _selectedCategoryId = ValueNotifier(null);
  late PageController _categoryPageController;
  List<String?> _categoryPages = [null];
  final ValueNotifier<int> _currentPageIndex = ValueNotifier(0);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _categoryPageController = PageController();
    _selectedUserId.value = widget.preselectedUser;
  }

  @override
  void didUpdateWidget(FollowingTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.preselectedUser != oldWidget.preselectedUser &&
        widget.preselectedUser != null) {
      _selectedUserId.value = widget.preselectedUser;
      _selectedCategoryId.value = null;
    }
  }

  @override
  void dispose() {
    if (widget.scrollController == null) _scrollController.dispose();
    _categoryPageController.dispose();
    _selectedUserId.dispose();
    _selectedCategoryId.dispose();
    _currentPageIndex.dispose();
    super.dispose();
  }

  void _handleUserSelection(String userId) {
    _selectedUserId.value = (_selectedUserId.value == userId) ? null : userId;
    _selectedCategoryId.value = null;
    _categoryPages = [null];
    _currentPageIndex.value = 0;

    if (_categoryPageController.hasClients) {
      _categoryPageController.jumpToPage(0);
    }

    if (_selectedUserId.value != null) {
      ref
          .read(followFeedNotifierProvider.notifier)
          .loadCategories(_selectedUserId.value!);
    }
  }

  void _handleCategorySelection(String categoryId) {
    final index = _categoryPages.indexOf(
      categoryId.isEmpty ? null : categoryId,
    );
    if (index != -1 && _categoryPageController.hasClients) {
      _categoryPageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _currentPageIndex.value = index;
    }
  }

  void _onCategoryPageChanged(int index) {
    final categoryId = _categoryPages[index];
    _selectedCategoryId.value = categoryId;
    _currentPageIndex.value = index;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final followFeedState = ref.watch(followFeedNotifierProvider);
    final allPosts = ref.watch(feedControllerProvider).value ?? [];

    // Pre-group posts by userId once — avoids inline .where() per page frame
    final Map<String, List<Map<String, dynamic>>> postsByUser = {};
    for (final post in allPosts) {
      final uid = post['userId'] as String?;
      if (uid == null) continue;
      postsByUser.putIfAbsent(uid, () => []).add(post);
    }

    return followFeedState.when(
      data: (state) {
        if (state.currentUser == null) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(height: 16.h),
                  Text('로그인이 필요합니다', style: theme.textTheme.titleLarge),
                  SizedBox(height: 8.h),
                  Text(
                    '내 페이지탭에서 회원가입 후 이용가능합니다',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.only(top: 10.h),
          child: Column(
            children: [
              SizedBox(
                height: 100.h,
                child:
                    state.followingUsers.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 32,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                '팔로우한 사용자가 없습니다',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        )
                        : ValueListenableBuilder<String?>(
                          valueListenable: _selectedUserId,
                          builder: (context, selectedId, _) {
                            if (selectedId == null &&
                                state.followingUsers.isNotEmpty) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  _handleUserSelection(
                                    state.followingUsers.first.userId,
                                  );
                                }
                              });
                            }
                            return FollowingUsersList(
                              followingUsers: state.followingUsers,
                              onUserTap: _handleUserSelection,
                              selectedUserId: selectedId,
                            );
                          },
                        ),
              ),
              Expanded(
                child: ValueListenableBuilder<String?>(
                  valueListenable: _selectedUserId,
                  builder: (context, selectedId, _) {
                    if (selectedId == null ||
                        state.effectiveBlockedUsers.contains(selectedId)) {
                      return const SizedBox.shrink();
                    }

                    _categoryPages = [
                      null,
                      ...state.categories.map((c) => c['id'] as String?),
                    ];

                    return Column(
                      children: [
                        ValueListenableBuilder<String?>(
                          valueListenable: _selectedCategoryId,
                          builder: (context, selectedCategoryId, _) {
                            return UserCategoriesBar(
                              categories: state.categories,
                              selectedCategoryId: selectedCategoryId,
                              onCategorySelected: _handleCategorySelection,
                            );
                          },
                        ),
                        Expanded(
                          child: PageView.builder(
                            controller: _categoryPageController,
                            onPageChanged: _onCategoryPageChanged,
                            itemCount: _categoryPages.length,
                            itemBuilder: (context, index) {
                              final catId = _categoryPages[index];
                              final userPosts = postsByUser[selectedId] ?? [];
                              final filteredPosts = catId == null
                                  ? userPosts
                                  : userPosts.where((p) => p['categoryId'] == catId).toList();
                              
                              return ValueListenableBuilder<int>(
                                valueListenable: _currentPageIndex,
                                builder: (context, activeIndex, _) {
                                  return FollowingPostsList(
                                    posts: filteredPosts,
                                    scrollController: (index == activeIndex) ? _scrollController : null,
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}


