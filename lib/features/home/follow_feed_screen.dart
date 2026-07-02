import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerece_app/features/home/domain/follow_feed_notifier.dart';
import 'package:ecommerece_app/features/home/widgets/following_users_list.dart';
import 'package:ecommerece_app/features/home/widgets/follow_feed_list.dart';
import 'package:ecommerece_app/features/home/widgets/proxy_scroll_controller.dart';

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
  final Map<int, ScrollController> _pageScrollControllers = {};
  final ValueNotifier<String?> _selectedUserId = ValueNotifier(null);
  final ValueNotifier<String?> _selectedCategoryId = ValueNotifier(null);
  late PageController _categoryPageController;
  List<String?> _categoryPages = [null];
  final ValueNotifier<int> _currentPageIndex = ValueNotifier(0);

  ScrollController _getScrollControllerForPage(int index) {
    final controller = _pageScrollControllers.putIfAbsent(index, () => ScrollController());
    if (index == _currentPageIndex.value) {
      _updateActiveController(index);
    }
    return controller;
  }

  void _updateActiveController(int index) {
    if (widget.scrollController is ProxyScrollController) {
      final proxy = widget.scrollController as ProxyScrollController;
      proxy.activeController = _pageScrollControllers[index];
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _categoryPageController = PageController();
    _selectedUserId.value = widget.preselectedUser;
    _updateActiveController(0);
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
    for (final controller in _pageScrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleUserSelection(String userId) {
    _selectedUserId.value = (_selectedUserId.value == userId) ? null : userId;
    _selectedCategoryId.value = null;
    _categoryPages = [null];
    _currentPageIndex.value = 0;
    _updateActiveController(0);

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
      _updateActiveController(index);
    }
  }

  void _onCategoryPageChanged(int index) {
    final categoryId = _categoryPages[index];
    _selectedCategoryId.value = categoryId;
    _currentPageIndex.value = index;
    _updateActiveController(index);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final followFeedState = ref.watch(followFeedNotifierProvider);

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
                              
                              return FollowingPostsList(
                                userId: selectedId,
                                categoryId: catId,
                                scrollController: _getScrollControllerForPage(index),
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


