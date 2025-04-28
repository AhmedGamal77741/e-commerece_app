import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/features/auth/auth_screen.dart';
import 'package:ecommerece_app/features/cart/order_complete.dart';
import 'package:ecommerece_app/features/cart/place_order.dart';
import 'package:ecommerece_app/features/home/add_post.dart';
import 'package:ecommerece_app/features/home/comments.dart';
import 'package:ecommerece_app/features/home/notifications.dart';
import 'package:ecommerece_app/features/mypage/ui/cancel_subscription.dart';
import 'package:ecommerece_app/features/navBar/nav_bar.dart';
import 'package:ecommerece_app/features/review/ui/exchange_or_refund.dart';
import 'package:ecommerece_app/features/review/ui/review_screen.dart';
import 'package:ecommerece_app/features/review/ui/track_order.dart';
import 'package:ecommerece_app/features/shop/item_details.dart';
import 'package:ecommerece_app/features/shop/shop_search.dart';
import 'package:ecommerece_app/landing.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: Routes.landingScreen,
    routes: [
      GoRoute(
        path: Routes.landingScreen,
        builder: (context, state) => const LandingScreen(),
        routes: [
          GoRoute(
            path: Routes.navBar,
            builder: (context, state) => const NavBar(),
          ),
          GoRoute(
            path: Routes.reviewScreen,
            builder: (context, state) => const ReviewScreen(),
          ),
          GoRoute(
            path: Routes.notificationsScreen,
            builder: (context, state) => const Notifications(),
          ),
          GoRoute(
            path: Routes.addPostScreen,
            builder: (context, state) => const AddPost(),
          ),
          GoRoute(
            path: Routes.placeOrderScreen,
            builder: (context, state) => const PlaceOrder(),
          ),
          GoRoute(
            path: Routes.orderCompleteScreen,
            builder: (context, state) => const OrderComplete(),
          ),
          GoRoute(
            path: Routes.shopSearchScreen,
            builder: (context, state) => const ShopSearch(),
          ),
          GoRoute(
            path: Routes.commentsScreen,
            builder: (context, state) {
              final postId = state.uri.queryParameters['postId'] ?? '';
              return Comments(postId: postId);
            },
          ),
          // Uncomment and update these routes as needed
          /*
      GoRoute(
        path: Routes.itemDetailsScreen,
        builder: (context, state) => ItemDetails(),
      ),
      GoRoute(
        path: Routes.trackorder,
        builder: (context, state) => const TrackOrder(),
      ),
      GoRoute(
        path: Routes.exchangeOrRefund,
        builder: (context, state) => const ExchangeOrRefund(),
      ),
      */
          GoRoute(
            path: Routes.cancelSubscription,
            builder: (context, state) => const CancelSubscription(),
          ),

          /*
      GoRoute(
        path: '${Routes.itemDetailsScreen}/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'];
          return ItemDetails(itemId: id);
        },
      ),       */
        ],
      ),
    ],
    errorBuilder:
        (context, state) => Scaffold(
          body: Center(child: Text('No route defined for ${state.uri.path}')),
        ),
  );
}
