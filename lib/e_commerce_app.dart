import 'package:ecommerece_app/core/routing/app_router.dart';

import 'package:ecommerece_app/core/theming/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EcommerceApp extends StatefulWidget {
  final AppRouter appRouter;
  const EcommerceApp({super.key, required this.appRouter});

  @override
  State<EcommerceApp> createState() => _EcommerceAppState();
}
class _EcommerceAppState extends State<EcommerceApp> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (kIsWeb) {
          return Center(
            child: SizedBox(
              width: 700,
              height: 926,
              child: ClipRect(
                child: MediaQuery(
                  data: MediaQueryData(
                    size: const Size(700, 926),
                    devicePixelRatio: MediaQuery.of(context).devicePixelRatio,
                  ),
                  child: ScreenUtilInit(
                    designSize: const Size(700, 926),
                    minTextAdapt: true,
                    builder:
                        (context, child) => MaterialApp.router(
                          title: 'E-commerce App (Web)',
                          theme: AppTheme.lightTheme,
                          debugShowCheckedModeBanner: false,
                          routerConfig: AppRouter.router,
                        ),
                  ),
                ),
              ),
            ),
          );
        } else {
          return ScreenUtilInit(
            designSize: const Size(428, 926),
            minTextAdapt: true,
            builder:
                (context, child) => MaterialApp.router(
                  title: 'E-commerce App',
                  theme: AppTheme.lightTheme,
                  debugShowCheckedModeBanner: false,
                  routerConfig: AppRouter.router,
                ),
          );
        }
      },
    );
  }
}
