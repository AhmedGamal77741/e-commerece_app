import 'package:app_links/app_links.dart';
import 'package:ecommerece_app/features/auth/signup/data/signup_functions.dart';
import 'package:ecommerece_app/features/home/data/post_provider.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ecommerece_app/core/routing/app_router.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/e_commerce_app.dart';
import 'package:ecommerece_app/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

late AppLinks _appLinks;
late GoRouter _router;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );

  _appLinks = AppLinks();
  _router = AppRouter.router;

  _handleInitialDeepLink();
  _handleDeepLinks();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PostsProvider()),
        Provider<FirebaseUserRepo>(create: (_) => FirebaseUserRepo()),
      ],
      child: EcommerceApp(appRouter: AppRouter()),
    ),
  );
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

  // ── Product routes: /product/:productId ───────────────────────────────────
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
  // app.pang2chocolate.com/bank-registered?success=...&userId=...&paymentId=...
  // OS intercepts → brings Flutter app to foreground → this handler runs.
  if (uri.path == Routes.bankRegisteredScreen) {
    final success = uri.queryParameters['success'] ?? 'false';
    final userId = uri.queryParameters['userId'] ?? '';
    final paymentId = uri.queryParameters['paymentId'] ?? '';
    final message = uri.queryParameters['message'] ?? '';
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
      },
    );
    return;
  }

  debugPrint('No matching route found for: ${uri.path}');
}
