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
    if (kIsWeb) {
      return MaterialApp.router(
        title: '팽이초콜릿',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.black,
            primary: Colors.black,
            onPrimary: Colors.white,
            secondary: Colors.black,
            onSecondary: Colors.white,
            surface: ColorsManager.primary,
          ),
          textSelectionTheme: const TextSelectionThemeData(
            cursorColor: Colors.black,
            selectionColor: Colors.black12,
            selectionHandleColor: Colors.black,
          ),
          scaffoldBackgroundColor: ColorsManager.primary,
          appBarTheme: const AppBarTheme(
            backgroundColor: ColorsManager.primary,
            surfaceTintColor: Colors.transparent,
          ),
          unselectedWidgetColor: Colors.grey,
          radioTheme: RadioThemeData(
            fillColor: WidgetStateColor.resolveWith(
              (states) => Colors.black,
            ),
          ),
          dialogTheme: const DialogThemeData(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            titleTextStyle: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
            contentTextStyle: TextStyle(
              color: Colors.black,
              fontSize: 15,
            ),
          ),
          progressIndicatorTheme: const ProgressIndicatorThemeData(
            color: Colors.black,
          ),
        ),
        debugShowCheckedModeBanner: false,
        routerConfig: AppRouter.router,
        builder: (context, child) {
          // Initialize ScreenUtil to match the exact size of the browser, making scale factor 1.0!
          // This safely disables ScreenUtil's dynamic scaling on the web.
          ScreenUtil.init(
            context,
            designSize: MediaQuery.of(context).size,
            minTextAdapt: true,
            splitScreenMode: true,
          );
          
          return Center(
            child: SizedBox(
              width: 428,
              child: ClipRect(
                child: child!,
              ),
            ),
          );
        },
      );    } else {
      return ScreenUtilInit(
        designSize: const Size(428, 926),
        minTextAdapt: true,
        splitScreenMode: true,
        ensureScreenSize: true,
                useInheritedMediaQuery: true,
        builder:
            (context, child) => MaterialApp.router(
              // scaffoldMessengerKey: scaffoldMessengerKey,
              title: '팽이초콜릿',
              theme: ThemeData(
                useMaterial3: true,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.black,
                  primary: Colors.black,
                  onPrimary: Colors.white,
                  secondary: Colors.black,
                  onSecondary: Colors.white,
                  surface: ColorsManager.primary,
                ),
                textSelectionTheme: const TextSelectionThemeData(
                  cursorColor: Colors.black,
                  selectionColor: Colors.black12,
                  selectionHandleColor: Colors.black,
                ),
                scaffoldBackgroundColor: ColorsManager.primary,
                appBarTheme: const AppBarTheme(
                  backgroundColor: ColorsManager.primary,
                  surfaceTintColor: Colors.transparent,
                ),
                unselectedWidgetColor: Colors.grey,
                radioTheme: RadioThemeData(
                  fillColor: WidgetStateColor.resolveWith(
                    (states) => Colors.black,
                  ),
                ),
                dialogTheme: const DialogThemeData(
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  titleTextStyle: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  contentTextStyle: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                  ),
                ),
              ),
              debugShowCheckedModeBanner: false,
              routerConfig: AppRouter.router,
            ),
      );
    }
  }
}
