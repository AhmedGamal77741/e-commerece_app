import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerece_app/features/home/domain/search_notifier.dart';
import 'package:ecommerece_app/features/home/widgets/user_search_tile.dart';
import 'package:ecommerece_app/features/home/widgets/post_item.dart';
import 'package:ecommerece_app/features/home/domain/feed_controller.dart';
import 'package:ecommerece_app/features/home/domain/follow_controller.dart';
import 'package:ecommerece_app/features/home/widgets/guest_preview.dart/guest_post_item.dart';
import 'package:ecommerece_app/core/providers/firebase_providers.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/features/shop/domain/shop_controller.dart';
import 'package:ecommerece_app/features/auth/domain/auth_controller.dart';
import 'package:ecommerece_app/core/helpers/basetime.dart';
import 'package:ecommerece_app/features/shop/item_details.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeSearch extends ConsumerStatefulWidget {
  final int initialTabIndex;
  final bool useGuestPostItem;

  const HomeSearch({
    super.key,
    this.initialTabIndex = 1,
    this.useGuestPostItem = false,
  });

  @override
  ConsumerState<HomeSearch> createState() => _HomeSearchState();
}

class _HomeSearchState extends ConsumerState<HomeSearch> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  late int _selectedIndex;
  
  final List<String> _tabs = ['???', '???', '??'];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex;
    _tabController = TabController(length: _tabs.length, vsync: this, initialIndex: _selectedIndex);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedIndex = _tabController.index;
        });
      }
    });

    _searchController.addListener(() {
      ref
          .read(searchNotifierProvider.notifier)
          .updateQuery(_searchController.text);
      setState(() {}); // trigger rebuild to pass new query to ShopSearchTab
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(30.r),
                    child: Icon(
                      Icons.arrow_back,
                      size: 36.r,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Container(
                      height: 45.h,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(30.r),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: '??',
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
            TabBar(
              controller: _tabController,
              labelStyle: TextStyle(
                fontSize: 16.sp,
                decoration: TextDecoration.none,
                fontFamily: 'NotoSans',
                fontStyle: FontStyle.normal,
                fontWeight: FontWeight.w400,
                letterSpacing: 0,
                color: ColorsManager.primaryblack,
              ),
              unselectedLabelColor: ColorsManager.primary600,
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorColor: ColorsManager.primaryblack,
              indicatorWeight: 2,
              tabs: _tabs.map((label) => Tab(text: label)).toList(),
            ),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  const _FollowingSearchTab(),
                  _HomeFeedSearchTab(useGuestPostItem: widget.useGuestPostItem),
                  _ShopSearchTab(searchQuery: _searchController.text),
                ],
              ),
            ),
          ],
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
          itemBuilder: (context, index) {
            final user = state.users[index];

            return StreamBuilder(
              stream: ref
                  .read(feedControllerProvider.notifier)
                  .getFollowingDocStream(currentUserId, user.userId),
              builder: (context, followingSnapshot) {
                final isFollowing =
                    followingSnapshot.hasData && followingSnapshot.data!.exists;

                return StreamBuilder(
                  stream: ref
                      .read(feedControllerProvider.notifier)
                      .getFollowRequestDocStream(user.userId, currentUserId),
                  builder: (context, requestSnapshot) {
                    final hasRequest =
                        requestSnapshot.hasData && requestSnapshot.data!.exists;

                    return UserSearchTile(
                      user: user,
                      isFollowing: isFollowing,
                      hasPendingRequest: hasRequest,
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
                    );
                  },
                );
              },
            );
          },
        );
      },
      loading: () => const Center(),
      error: (e, st) => Center(child: Text('Error: ')),
    );
  }
}

class _HomeFeedSearchTab extends ConsumerWidget {
  final bool useGuestPostItem;
  const _HomeFeedSearchTab({required this.useGuestPostItem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(searchNotifierProvider);

    return searchState.when(
      data: (state) {
        if (state.posts.isEmpty) return const SizedBox.shrink();

        return ListView.builder(
          itemCount: state.posts.length,
          itemBuilder: (context, index) {
            final post = state.posts[index];
            final postId = post['postId'] ?? post['id'];
            if (postId == null) return const SizedBox.shrink();

            return useGuestPostItem
                ? GuestPostItem(post: post)
                : PostItem(postId: postId, fromComments: false);
          },
        );
      },
      loading: () => const Center(),
      error: (e, st) => Center(child: Text('Error: ')),
    );
  }
}

class _ShopSearchTab extends ConsumerWidget {
  final String searchQuery;
  const _ShopSearchTab({required this.searchQuery});
  
  static final _formatCurrency = NumberFormat('#,###');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return const SizedBox.shrink();

    final productsAsync = ref.watch(categoryProductsStreamProvider('all'));
    final isSub = ref.watch(isSubscribedProvider).value ?? false;

    return productsAsync.when(
      data: (products) {
        final filtered = products.where((p) => p.productName.toLowerCase().contains(query)).toList();
        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final product = filtered[index];
            return ListTile(
              title: Text(product.productName),
              subtitle: isSub
                  ? Text('\ ?')
                  : Text('\ ?'),
              leading: (product.imgUrl != null && product.imgUrl!.isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: product.imgUrl!,
                      width: 50.w,
                      height: 50.h,
                      fit: BoxFit.cover,
                    )
                  : SizedBox(width: 50.w, height: 50.h),
              onTap: () async {
                String arrivalTime = await getArrivalDay(
                  product.meridiem,
                  product.baselineTime,
                );
                if (!context.mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ItemDetails(
                      product: product,
                      arrivalDay: arrivalTime,
                      isSub: isSub,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const Center(),
      error: (e, st) => Center(child: Text('Error: ')),
    );
  }
}
