import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/features/auth/domain/auth_controller.dart';
import 'package:ecommerece_app/features/home/domain/feed_controller.dart' show hasUnreadNotificationsProvider;

class HomeAppBarPills extends ConsumerWidget {
  final User? firebaseUser;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const HomeAppBarPills({
    super.key,
    required this.firebaseUser,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  static const List<Map<String, dynamic>> _userTabs = [
    {'label': '추천'},
    {'label': '구독'},
    {'label': 'MY'},
  ];

  static const List<Map<String, dynamic>> _nonUserTabs = [
    {'label': '추천'},
  ];

  Widget _buildPill(BuildContext context, int index, String label) {
    final bool isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () => onTabSelected(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'NotoSans',
            fontSize: 14.sp,
            color: isSelected ? const Color(0xFF424242) : const Color(0xFF9E9E9E),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabs = firebaseUser == null ? _nonUserTabs : _userTabs;

    return Padding(
      padding: EdgeInsets.fromLTRB(5.w, 0, 5.w, 5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        key: const ValueKey('pills'),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < tabs.length; i++) ...[
                  _buildPill(context, i, tabs[i]['label']),
                  if (i < tabs.length - 1) SizedBox(width: 8.w),
                ],
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(
                onTap: () {
                  if (firebaseUser == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("검색은 회원가입 후 이용가능합니다")),
                    );
                    return;
                  }
                  context.pushNamed(Routes.alertsScreen);
                },
                child: _NotificationBellIcon(firebaseUser: firebaseUser),
              ),
              InkWell(
                onTap: () {
                  final currentUser = ref.read(currentUserProvider).value;
                  if (currentUser != null && currentUser.type != 'guest') {
                    if (currentUser.defaultAddressId == null || currentUser.defaultAddressId!.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('주소를 먼저 등록해주세요.')),
                      );
                      return;
                    }
                  }
                  context.pushNamed(Routes.shopSearchScreen, extra: {'initialTabIndex': 1});
                },
                child: ImageIcon(
                  const AssetImage('assets/search_icon.png'),
                  color: Theme.of(context).iconTheme.color,
                  size: 30.r,
                ),
              ),
              horizontalSpace(5),
            ],
          ),
        ],
      ),
    );
  }
}

/// Isolated widget so notification dot changes never rebuild the entire AppBar.
class _NotificationBellIcon extends ConsumerWidget {
  final User? firebaseUser;
  const _NotificationBellIcon({required this.firebaseUser});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (firebaseUser == null) {
      return Image.asset(
        'assets/notification_bell_transparent.png',
        height: 35.h,
        width: 35.w,
      );
    }

    final hasUnread = ref.watch(hasUnreadNotificationsProvider).value ?? false;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Image.asset(
          'assets/notification_bell_transparent.png',
          height: 35.h,
          width: 35.w,
        ),
        if (hasUnread)
          Positioned(
            left: 0.w,
            top: 0.h,
            child: Image.asset(
              'assets/notification_dot.png',
              width: 18.w,
              height: 18.h,
            ),
          ),
      ],
    );
  }
}
