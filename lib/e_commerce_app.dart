import 'package:ecommerece_app/core/routing/app_router.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EcommerceApp extends StatelessWidget {
  final AppRouter appRouter;
  const EcommerceApp({super.key, required this.appRouter});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(428, 926),
      minTextAdapt: true,
      child: MaterialApp(
        theme: ThemeData(
          scaffoldBackgroundColor: Colors.white,
          unselectedWidgetColor: Colors.grey, // Unselected circle color
          radioTheme: RadioThemeData(
            fillColor: WidgetStateColor.resolveWith((states) => Colors.black),
          ),
        ),
        debugShowCheckedModeBanner: false,
        initialRoute: Routes.authScreen,
        onGenerateRoute: appRouter.generateRoute,
      ),
    );
  }
}
