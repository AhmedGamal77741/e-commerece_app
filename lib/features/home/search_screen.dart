import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerece_app/features/shop/shop_search.dart';
import 'package:ecommerece_app/features/home/domain/search_notifier.dart';
import 'package:ecommerece_app/features/home/widgets/user_search_tile.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:ecommerece_app/features/home/widgets/post_item.dart';
import 'package:ecommerece_app/features/home/domain/feed_controller.dart';
import 'package:ecommerece_app/features/home/domain/follow_controller.dart';
import 'package:ecommerece_app/features/home/widgets/guest_preview.dart/guest_post_item.dart';
import 'package:ecommerece_app/core/providers/firebase_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/features/auth/domain/auth_controller.dart';
import 'dart:async';

class HomeSearch extends ConsumerStatefulWidget {
  final bool useGuestPostItem;
  final int initialTabIndex;
  const HomeSearch({
    super.key,
    this.useGuestPostItem = false,
    this.initialTabIndex = 1,
  });

  @override
  ConsumerState<HomeSearch> createState() => _HomeSearchState();
}

class _HomeSearchState extends ConsumerState<HomeSearch> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  late int _selectedIndex;
  final List<Map<String, dynamic>> _userTabs = [
    {'label': '프로필'},
    {'label': '게시글'},
    {'label': '쇼핑'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedIndex == 2) {
        final currentUser = ref.read(currentUserProvider).value;
        if (currentUser != null && currentUser.type != 'guest') {
          if (currentUser.defaultAddressId == null || currentUser.defaultAddressId!.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('주소를 먼저 등록해주세요.')),
            );
            setState(() {
              _selectedIndex = 1;
            });
          }
        }
      }
    });

    _searchController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), () {
        ref
            .read(searchNotifierProvider.notifier)
            .updateQuery(_searchController.text);
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildPill(BuildContext context, int index) {
    final theme = Theme.of(context);
    final bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 2) {
          final currentUser = ref.read(currentUserProvider).value;
          if (currentUser != null && currentUser.type != 'guest') {
            if (currentUser.defaultAddressId == null || currentUser.defaultAddressId!.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('주소를 먼저 등록해주세요.')),
              );
              return;
            }
          }
        }
        setState(() => _selectedIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Colors.white
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _userTabs[index]['label'],
          style: theme.textTheme.labelMedium?.copyWith(
            color:
                isSelected
                    ? Colors.black
                    : theme.colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: kIsWeb,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.mounted) {
          context.pop();
        }
      },
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.grey[100],
          body: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => context.pop(),
                      borderRadius: BorderRadius.circular(30.r),
                      child: Icon(
                        Icons.arrow_back,
                        size: 36.r,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 42.h,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          textAlignVertical: TextAlignVertical.center,
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20.h,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(5.w, 0, 5.w, 5.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (int i = 0; i < _userTabs.length; i++) ...[
                            _buildPill(context, i),
                            if (i < _userTabs.length - 1) SizedBox(width: 8.w),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    IndexedStack(
                      index: _selectedIndex,
                      children: [
                        const _FollowingSearchTab(),
                        _HomeFeedSearchTab(useGuestPostItem: widget.useGuestPostItem),
                        ShopSearch(),
                      ],
                    ),
                    Consumer(
                      builder: (context, ref, child) {
                        final searchState = ref.watch(searchNotifierProvider);
                        final isLoading = searchState.value?.isLoading ?? false;
                        if (isLoading) {
                          return const Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: LinearProgressIndicator(
                              color: Colors.black,
                              backgroundColor: Colors.transparent,
                              minHeight: 2,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FollowingSearchTab extends ConsumerWidget {
  const _FollowingSearchTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(searchNotifierProvider);
    final currentUserId = ref.watch(currentUserIdProvider);

    return searchState.when(
      data: (state) {
        if (state.users.isEmpty) return const SizedBox.shrink();

        return ListView.builder(
          itemCount: state.users.length,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: false,
          itemBuilder: (context, index) {
            final user = state.users[index];
            return RepaintBoundary(
              key: ValueKey(user.userId),
              child: _UserSearchTileWrapper(
                user: user,
                currentUserId: currentUserId,
              ),
            );
          },
        );
      },
      loading: () => const Center(),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}

class _UserSearchTileWrapper extends ConsumerWidget {
  final MyUser user;
  final String currentUserId;

  const _UserSearchTileWrapper({
    required this.user,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isFollowing = currentUserId.isEmpty
        ? false
        : (ref.watch(isFollowingProvider(user.userId)).value ?? false);

    final bool hasRequest = currentUserId.isEmpty
        ? false
        : (ref.watch(hasFollowRequestProvider(user.userId)).value ?? false);

    return InkWell(
      onTap: () => context.pushNamed(Routes.profileTabScreen, extra: {'userId': user.userId}),
      child: UserSearchTile(
        user: user,
        isFollowing: isFollowing,
        hasPendingRequest: hasRequest,
        hideFollowButton: currentUserId.isEmpty,
        onToggleFollow:
            () => ref
                .read(followControllerProvider)
                .toggleFollow(user.userId),
        onToggleRequest: () async {
          if (hasRequest) {
            await ref
                .read(followControllerProvider)
                .cancelFollowRequest(user.userId, currentUserId);
          } else {
            await ref
                .read(followControllerProvider)
                .sendFollowRequest(user.userId, currentUserId);
          }
        },
      ),
    );
  }
}

class _HomeFeedSearchTab extends ConsumerWidget {
  final bool useGuestPostItem;
  const _HomeFeedSearchTab({required this.useGuestPostItem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(searchNotifierProvider);
    final currentUserId = ref.watch(currentUserIdProvider);
    final isGuest = currentUserId.isEmpty;

    return searchState.when(
      data: (state) {
        if (state.posts.isEmpty) return const SizedBox.shrink();

        return ListView.builder(
          itemCount: state.posts.length,
          cacheExtent: 1200,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: false,
          itemBuilder: (context, index) {
            final post = state.posts[index];
            final postId = post['postId'] ?? post['id'];
            if (postId == null) return const SizedBox.shrink();

            return RepaintBoundary(
              key: ValueKey(postId),
              child: useGuestPostItem || isGuest
                  ? GuestPostItem(post: post)
                  : PostItem(
                      postId: postId,
                      fromComments: false,
                      postData: post,
                    ),
            );
          },
        );
      },
      loading: () => const Center(),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}
