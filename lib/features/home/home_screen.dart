import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerece_app/core/providers/firebase_providers.dart';
import 'package:ecommerece_app/features/home/follow_feed_screen.dart';
import 'package:ecommerece_app/features/home/my_story.dart';
import 'package:ecommerece_app/features/home/widgets/home_feed_tab.dart';
import 'package:ecommerece_app/features/home/widgets/home_app_bar_pills.dart';
import 'package:ecommerece_app/features/home/widgets/home_fab.dart';

import 'package:ecommerece_app/features/home/widgets/proxy_scroll_controller.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final ScrollController? scrollController;
  final TabController? tabController;
  const HomeScreen({super.key, this.scrollController, this.tabController});

  @override
  ConsumerState<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends ConsumerState<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  int _selectedIndex = 0;
  late final ScrollController _feedTabController;
  late final ProxyScrollController _followingTabController;
  late final ScrollController _myStoryTabController;
  final List<bool> _tabInitialized = [false, false, false];

  void resetToTop() {
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
    final controller = _selectedIndex == 0
        ? _feedTabController
        : _selectedIndex == 1
            ? _followingTabController
            : _myStoryTabController;

    if (controller.hasClients) {
      controller.animateTo(
        0,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _feedTabController = ScrollController();
    _followingTabController = ProxyScrollController();
    _myStoryTabController = ScrollController();
    // Defer feed initialization to after the first frame so the navbar
    // and scaffold render fast before firing the Firestore query.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _tabInitialized[0] = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _feedTabController.dispose();
    _followingTabController.dispose();
    _myStoryTabController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
      _tabInitialized[index] = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final authState = ref.watch(authStateProvider);
    final firebaseUser = authState.value;

    return SafeArea(
      child: Scaffold(
        floatingActionButton: HomeFAB(
          firebaseUser: firebaseUser,
          selectedIndex: _selectedIndex,
        ),
        body: Column(
          children: [
            HomeAppBarPills(
              firebaseUser: firebaseUser,
              selectedIndex: _selectedIndex,
              onTabSelected: _onTabSelected,
            ),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  _tabInitialized[0]
                      ? HomeFeedTab(scrollController: _feedTabController)
                      : const SizedBox.shrink(),
                  _tabInitialized[1]
                      ? FollowingTab(scrollController: _followingTabController)
                      : const SizedBox.shrink(),
                  _tabInitialized[2]
                      ? MyStory(scrollController: _myStoryTabController)
                      : const SizedBox.shrink(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
