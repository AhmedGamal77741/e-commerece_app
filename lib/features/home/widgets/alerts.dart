import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/features/home/notifications.dart';
import 'package:ecommerece_app/features/home/widgets/requests.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class Alerts extends ConsumerWidget {
  const Alerts({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: kIsWeb,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.mounted) {
          context.pop();
        }
      },
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(
                Icons.close,
                color: ColorsManager.primaryblack,
                size: 24.sp,
              ),
              onPressed: () => context.pop(),
            ),
            centerTitle: true,
            title: SizedBox(
              width: 300.w,
              child: TabBar(
                tabs: [Tab(text: '알림'), Tab(text: '친구관리')],
                labelStyle: TextStyle(
                  fontSize: 16.sp,
                  decoration: TextDecoration.none,
                  fontFamily: 'NotoSans',
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0,
                  color: ColorsManager.primaryblack,
                ),
                unselectedLabelColor: ColorsManager.primary600,
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorColor: ColorsManager.primaryblack,
              ),
            ),
          ),
          body: const TabBarView(children: [Notifications(), Requests()]),
        ),
      ),
    );
  }
}
