import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/features/home/domain/feed_controller.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => onTabSelected(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.surface : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            fontSize: 12.sp,
            color: isSelected ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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
                child: firebaseUser == null
                    ? Image.asset(
                        'assets/notification_bell_transparent.png',
                        height: 35.h,
                        width: 35.w,
                      )
                    : StreamBuilder(
                        stream: ref.read(feedControllerProvider.notifier).getUnreadNotificationsStream(firebaseUser!.uid),
                        builder: (context, notifSnapshot) {
                          final hasUnread = notifSnapshot.hasData && notifSnapshot.data!.docs.isNotEmpty;
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
                        },
                      ),
              ),
              InkWell(
                onTap: () {
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
