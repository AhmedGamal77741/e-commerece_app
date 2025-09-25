import 'package:ecommerece_app/core/routing/app_router.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
//     GlobalKey<ScaffoldMessengerState>();

class EcommerceApp extends StatefulWidget {
  final AppRouter appRouter;
  const EcommerceApp({super.key, required this.appRouter});

  @override
  State<EcommerceApp> createState() => _EcommerceAppState();
}

class _EcommerceAppState extends State<EcommerceApp> {
  // late final AppLinks _appLinks;
  // StreamSubscription<Uri>? _linkSub;

  // @override
  // void initState() {
  //   super.initState();
  //   _appLinks = AppLinks();
  //   _listenForLinks();
  // }

  // void _listenForLinks() async {
  //   try {
  //     final initialUri = await _appLinks.getInitialLink();
  //     if (initialUri != null) {
  //       _handleUri(initialUri);
  //     }
  //   } catch (e) {
  //     debugPrint('Initial link error: \$e');
  //   }

  //   _linkSub = _appLinks.uriLinkStream.listen(
  //     (uri) {
  //       _handleUri(uri);
  //     },
  //     onError: (err) {
  //       debugPrint('Stream link error: \$err');
  //     },
  //   );
  // }

  // void _handleUri(Uri uri) {
  //   if (uri.scheme == 'paymentresult' && uri.host == 'callback') {
  //     final state = uri.queryParameters['PCD_PAY_STATE'];
  //     final isSuccess = state == '00';
  //     scaffoldMessengerKey.currentState?.showSnackBar(
  //       SnackBar(
  //         content: Text(isSuccess ? 'Payment Success' : 'Payment Failed'),
  //         backgroundColor: isSuccess ? Colors.green : Colors.red,
  //       ),
  //     );
  //   }
  // }

  // @override
  // void dispose() {
  //   _linkSub?.cancel();
  //   super.dispose();
  // }

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
                          // scaffoldMessengerKey: scaffoldMessengerKey,
                          title: 'E-commerce App (Web)',
                          theme: ThemeData(
                            scaffoldBackgroundColor: ColorsManager.primary,
                            appBarTheme: AppBarTheme(
                              backgroundColor: ColorsManager.primary,
                            ),
                            unselectedWidgetColor: Colors.grey,
                            radioTheme: RadioThemeData(
                              fillColor: WidgetStateColor.resolveWith(
                                (states) => Colors.black,
                              ),
                            ),
                          ),
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
                  // scaffoldMessengerKey: scaffoldMessengerKey,
                  title: 'E-commerce App',
                  theme: ThemeData(
                    scaffoldBackgroundColor: ColorsManager.primary,
                    appBarTheme: AppBarTheme(
                      backgroundColor: ColorsManager.primary,
                    ),
                    unselectedWidgetColor: Colors.grey,
                    radioTheme: RadioThemeData(
                      fillColor: WidgetStateColor.resolveWith(
                        (states) => Colors.black,
                      ),
                    ),
                  ),
                  debugShowCheckedModeBanner: false,
                  routerConfig: AppRouter.router,
                ),
          );
        }
      },
    );
  }
}
