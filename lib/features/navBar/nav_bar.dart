import 'package:ecommerece_app/core/providers/firebase_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/features/chat/ui/chats_navbar.dart';
import 'package:ecommerece_app/features/home/home_screen.dart';
import 'package:ecommerece_app/features/shop/shop.dart';
import 'package:ecommerece_app/landing.dart';
import 'package:flutter/material.dart';
import 'package:ecommerece_app/core/widgets/deleted_account.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/nav_bar_providers.dart';
import 'widgets/chat_nav_icon.dart';

class NavBar extends ConsumerStatefulWidget {
  const NavBar({super.key});

  @override
  ConsumerState<NavBar> createState() => _NavBarState();
}

class _NavBarState extends ConsumerState<NavBar> with TickerProviderStateMixin {
  final shopKey = GlobalKey<ShopState>();
  final homeKey = GlobalKey<HomeScreenState>();
  int _selectedIndex = 0;
  DateTime? _lastBackPressTime;

  final ScrollController homeScrollController = ScrollController();
  late TabController homeTabController;

  @override
  void initState() {
    super.initState();
    homeTabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingNavigation();
    });
  }

  @override
  void dispose() {
    homeTabController.dispose();
    homeScrollController.dispose();
    super.dispose();
  }

  Future<void> _checkPendingNavigation() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingSource = prefs.getString('pending_nav_source');
    if (pendingSource == null) return;
    await prefs.remove('pending_nav_source');
    if (!mounted) return;

    if (pendingSource == 'sub') {
      await _navigateToSubscription();
    } else if (pendingSource == 'shop') {
      await _onItemTapped(3);
    }
  }

  Future<void> _navigateToSubscription() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final navBarService = ref.read(navBarServiceProvider);

    final hasBankAccount = await navBarService.hasBankAccount(user.uid);

    if (!hasBankAccount) {
      if (!mounted) return;
      await context.pushNamed(
        Routes.noBankAccountScreen,
        queryParameters: {'source': 'sub'},
      );
      final nowHasAccount = await navBarService.hasBankAccount(user.uid);
      if (!nowHasAccount) return;
    }

    final hasReceiptData = await navBarService.hasReceiptData(user.uid);

    if (!hasReceiptData) {
      if (!mounted) return;
      final result = await context.pushNamed<bool>(
        Routes.receiptSetupScreen,
        queryParameters: {'source': 'sub'},
      );
      if (result != true) return;
    }

    if (mounted) {
      context.push(Routes.subscriptionScreen);
    }
  }

  Future<void> _onItemTapped(int index) async {
    if (_selectedIndex == index && index == 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        shopKey.currentState?.resetToFirstCategory();
      });
      return;
    }
    if (index == 0) {
      if (_selectedIndex == 0) {
        homeKey.currentState?.resetToTop();
      }
      setState(() {
        _selectedIndex = 0;
      });
      return;
    } else if (index == 3) {
      final user = ref.read(authStateProvider).value;
      if (user != null) {
        final navBarService = ref.read(navBarServiceProvider);

        final isDeleted = await navBarService.isAccountDeleted(user.uid);
        if (isDeleted) {
          setState(() {
            _selectedIndex = index;
          });
          return;
        }

        final hasBankAccount = await navBarService.hasBankAccount(user.uid);

        if (!hasBankAccount) {
          if (!mounted) return;
          final result = await context.pushNamed<bool>(
            Routes.noBankAccountScreen,
            queryParameters: {'source': 'shop'},
          );
          if (result != true) {
            final nowHasAccount = await navBarService.hasBankAccount(user.uid);
            if (!nowHasAccount) return;
          }
        }

        final hasReceiptData = await navBarService.hasReceiptData(user.uid);

        if (!hasReceiptData) {
          if (!mounted) return;
          final result = await context.pushNamed<dynamic>(
            Routes.receiptSetupScreen,
            queryParameters: {'source': 'shop'},
          );
          if (result != true && result != 'skip') return;
        }

        final hasDefaultAddress = await navBarService.hasDefaultAddress(
          user.uid,
        );
        if (!hasDefaultAddress) {
          if (!mounted) return;
          final result = await context.pushNamed<bool>(
            Routes.addAddressScreen,
            extra: {'showSkip': false},
          );

          if (result != true) {
            final nowHasAddress = await navBarService.hasDefaultAddress(
              user.uid,
            );
            if (!nowHasAddress) return;
          }
        }
      }
      setState(() {
        _selectedIndex = index;
      });
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

    final children = [
      HomeScreen(
        key: homeKey,
        scrollController: homeScrollController,
        tabController: homeTabController,
      ),
      const ChatsNavbar(),
      const Center(child: Text('멤버십 라운지')),
      Shop(key: shopKey),
      const LandingScreen(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        // On a non-home tab → navigate to home first
        if (_selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
          return;
        }
        // On home tab → require double-tap to exit
        final now = DateTime.now();
        if (_lastBackPressTime == null ||
            now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('한 번 더 누르면 종료됩니다'),
                duration: Duration(seconds: 2),
              ),
            );
          }
          return;
        }
        // Double-tap confirmed → exit
        // ignore: use_build_context_synchronously
        Navigator.of(context).pop();
      },
      child: Scaffold(
      // Isolated Consumer: only this subtree rebuilds when auth/profile streams emit.
      // The BottomNavigationBar and outer Scaffold are untouched.
      body: RepaintBoundary(
        child: Consumer(
          builder: (context, ref, _) {
            final user = ref.watch(authStateProvider).value;
            if (user == null) {
              return IndexedStack(index: _selectedIndex, children: children);
            }
            final userProfileAsync = ref.watch(userProfileStreamProvider);
            if (userProfileAsync.hasValue) {
              final userData = userProfileAsync.value;
              if (userData != null && userData['deleted'] == true) {
                return DeletedAccount(
                  deletedAt: userData['deletedAt']?.toString() ?? '',
                  onRecover: () async {
                    await ref
                        .read(navBarServiceProvider)
                        .recoverAccount(user.uid);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('계정이 복구되었습니다.')),
                      );
                    }
                  },
                  onSignOut: () async {
                    await ref.read(navBarServiceProvider).signOut();
                  },
                );
              }
            }
            return IndexedStack(index: _selectedIndex, children: children);
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: theme.colorScheme.surface,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: theme.textTheme.labelSmall?.copyWith(
          fontSize: 10.sp,
        ),
        unselectedLabelStyle: theme.textTheme.labelSmall?.copyWith(
          fontSize: 10.sp,
        ),
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Image.asset(
              _selectedIndex == 0 ? 'assets/001m.png' : 'assets/grey_001m.png',
              width: 30.r,
              height: 30.r,
              gaplessPlayback: true,
              cacheWidth: (30 * devicePixelRatio).toInt(),
            ),
            label: '상점',
          ),
          const BottomNavigationBarItem(
            icon: ChatNavIcon(isActive: false),
            activeIcon: ChatNavIcon(isActive: true),
            label: '채팅',
          ),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              radius: 30.r,
              backgroundColor: Colors.transparent,
              backgroundImage: const AssetImage(
                'assets/mypage_avatar_grey.png',
              ),
            ),
            activeIcon: CircleAvatar(
              radius: 30.r,
              backgroundColor: Colors.transparent,
              backgroundImage: const AssetImage('assets/mypage_avatar.png'),
            ),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              _selectedIndex == 3 ? 'assets/002m.png' : 'assets/grey_002m.png',
              width: 30.r,
              height: 30.r,
              gaplessPlayback: true,
              cacheWidth: (30 * devicePixelRatio).toInt(),
            ),
            label: '장바구니',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              _selectedIndex == 4 ? 'assets/005m.png' : 'assets/grey_005m.png',
              width: 30.r,
              height: 30.r,
              gaplessPlayback: true,
              cacheWidth: (30 * devicePixelRatio).toInt(),
            ),
            label: '내페이지',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    ),
    );
  }
}
