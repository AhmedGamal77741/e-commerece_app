import 'package:flutter/services.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ecommerece_app/core/routing/app_router.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/e_commerce_app.dart';
import 'package:ecommerece_app/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerece_app/features/chat/services/contacts_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ecommerece_app/core/helpers/error_logger.dart';

import 'package:ecommerece_app/core/services/notification_service.dart';

late AppLinks _appLinks;
late GoRouter _router;

void main() async {
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  await ScreenUtil.ensureScreenSize();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFFEEEEEE),
      systemNavigationBarDividerColor: Color(0xFFEEEEEE),
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  // Set production-ready image cache limits (200 MB and 1000 images max)
  // This balances seamless scroll-up caching (holding ~100-130 downsampled images) with RAM safety on low-end devices.
  PaintingBinding.instance.imageCache.maximumSize = 1000;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 200 * 1024 * 1024;

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set up global error logging for the app.
  FlutterError.onError = (errorDetails) {
    ErrorLogger.logGeneralError(
      message: 'Unhandled Flutter Error',
      error: errorDetails.exception,
      stackTrace: errorDetails.stack,
    );
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    ErrorLogger.logGeneralError(
      message: 'Unhandled Platform/Async Error',
      error: error,
      stackTrace: stack,
    );
    return true;
  };

  // Pre-load contact name map on startup to prevent async disk I/O during list scrolling
  await ContactService().loadContactNameMap();

  if (!kIsWeb) {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
    );
    await NotificationService.instance.init();
  }

  _router = AppRouter.router;

  if (!kIsWeb) {
    _appLinks = AppLinks();
    _handleInitialDeepLink();
    _handleDeepLinks();
  }

  runApp(ProviderScope(child: EcommerceApp(appRouter: AppRouter())));
}

void _handleInitialDeepLink() async {
  try {
    final initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) {
      debugPrint('Initial deep link received: $initialLink');
      _routeDeepLink(initialLink);
    }
  } catch (e) {
    debugPrint('Error handling initial deep link: $e');
  }
}

void _handleDeepLinks() {
  _appLinks.uriLinkStream.listen(
    (Uri uri) {
      debugPrint('Deep link received while app running: $uri');
      _routeDeepLink(uri);
    },
    onError: (err) {
      debugPrint('Error listening to deep links: $err');
    },
  );
}

void _routeDeepLink(Uri uri) {
  debugPrint('Routing deep link: ${uri.path} | Query: ${uri.queryParameters}');

  // ── Product routes: /product/:productId or /item-details ─────────────────
  if (uri.path.startsWith('/product/')) {
    final productId = uri.pathSegments.length > 1 ? uri.pathSegments[1] : '';
    if (productId.isNotEmpty) {
      debugPrint('Navigating to product: $productId');
      _router.pushNamed(
        'productDetails',
        pathParameters: {'productId': productId},
      );
      return;
    }
  }

  if (uri.path == '/item-details' || uri.path == Routes.itemDetailsScreen) {
    final productId = uri.queryParameters['productId'] ?? '';
    if (productId.isNotEmpty) {
      debugPrint('Navigating to item-details product: $productId');
      _router.pushNamed(
        'productDetails',
        pathParameters: {'productId': productId},
      );
      return;
    }
  }

  // ── Comment routes: /comment or /guest_comment ────────────────────────────
  if (uri.path == '/comment' || uri.path == '/guest_comment') {
    final postId = uri.queryParameters['postId'] ?? '';
    if (postId.isNotEmpty) {
      debugPrint('Navigating to comments for post: $postId');
      _router.pushNamed(
        'guestCommentsScreen',
        queryParameters: {'postId': postId},
      );
      return;
    }
  }

  // ── Bank registered: /bank-registered ─────────────────────────────────────
  // Fired when handleBankRegCallback HTML page navigates to
  // www.pang2chocolate.com/bank-registered?success=...&userId=...&paymentId=...
  // OS intercepts → brings Flutter app to foreground → this handler runs.
  if (uri.path == Routes.bankRegisteredScreen) {
    final success = uri.queryParameters['success'] ?? 'false';
    final userId = uri.queryParameters['userId'] ?? '';
    final paymentId = uri.queryParameters['paymentId'] ?? '';
    final message = uri.queryParameters['message'] ?? '';
    final source = uri.queryParameters['source'] ?? 'shop';
    debugPrint(
      'Bank registered deep link → success=$success '
      'userId=$userId paymentId=$paymentId',
    );
    _router.pushNamed(
      'bankRegisteredScreen',
      queryParameters: {
        'success': success,
        'userId': userId,
        'paymentId': paymentId,
        'message': message,
        'source': source,
      },
    );
    return;
  }

  debugPrint('No matching route found for: ${uri.path}');
}
