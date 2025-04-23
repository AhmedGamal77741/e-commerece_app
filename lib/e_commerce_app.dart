import 'package:ecommerece_app/core/routing/app_router.dart';
import 'package:ecommerece_app/landing.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EcommerceApp extends StatelessWidget {
  final AppRouter appRouter;
  const EcommerceApp({super.key, required this.appRouter});

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
                    devicePixelRatio: 1.0,
                  ),
                  child: ScreenUtilInit(
                    designSize: const Size(700, 926),
                    minTextAdapt: true,
                    builder:
                        (context, child) => MaterialApp(
                          theme: ThemeData(
                            scaffoldBackgroundColor: Colors.white,
                            unselectedWidgetColor: Colors.grey,
                            radioTheme: RadioThemeData(
                              fillColor: WidgetStateColor.resolveWith(
                                (states) => Colors.black,
                              ),
                            ),
                          ),
                          debugShowCheckedModeBanner: false,
                          onGenerateRoute: appRouter.generateRoute,
                          home: const LandingScreen(),
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
                (context, child) => MaterialApp(
                  theme: ThemeData(
                    scaffoldBackgroundColor: Colors.white,
                    unselectedWidgetColor: Colors.grey,
                    radioTheme: RadioThemeData(
                      fillColor: WidgetStateColor.resolveWith(
                        (states) => Colors.black,
                      ),
                    ),
                  ),
                  debugShowCheckedModeBanner: false,
                  onGenerateRoute: appRouter.generateRoute,
                  home: const LandingScreen(),
                ),
          );
        }
      },
    );
  }
}
