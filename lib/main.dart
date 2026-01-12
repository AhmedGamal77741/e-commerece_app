import 'package:app_links/app_links.dart';
import 'package:ecommerece_app/features/auth/signup/data/signup_functions.dart';
import 'package:ecommerece_app/features/home/data/post_provider.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ecommerece_app/core/routing/app_router.dart';
import 'package:ecommerece_app/e_commerce_app.dart';
import 'package:ecommerece_app/firebase_options.dart';
// import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'package:firebase_core/firebase_core.dart';

late AppLinks _appLinks;
late GoRouter _router;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //setUrlStrategy(PathUrlStrategy());

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug, // Use PlayIntegrity for production
    appleProvider:
        AppleProvider.debug, // Use DeviceCheck/AppAttest for production
  );
  _appLinks = AppLinks();
  _router = AppRouter.router;

  // Handle deep links from cold start
  _handleInitialDeepLink();

  // Handle deep links while app is running
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

  // Handle product routes: /product/:productId
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

  // Handle comment routes: /comment or /guest_comment
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

  debugPrint('No matching route found for: ${uri.path}');
}
