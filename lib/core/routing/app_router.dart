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
import 'package:flutter/material.dart';

class AppRouter {
  Route generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.navBar:
        return MaterialPageRoute(builder: (_) => const NavBar());
      case Routes.reviewScreen:
        return MaterialPageRoute(builder: (_) => const ReviewScreen());

      case Routes.notificationsScreen:
        return MaterialPageRoute(builder: (_) => const Notifications());
      case Routes.addPostScreen:
        return MaterialPageRoute(builder: (_) => const AddPost());
      case Routes.placeOrderScreen:
        return MaterialPageRoute(builder: (_) => const PlaceOrder());
      case Routes.orderCompleteScreen:
        return MaterialPageRoute(builder: (_) => const OrderComplete());
      case Routes.shopSearchScreen:
        return MaterialPageRoute(builder: (_) => const ShopSearch());
      // case Routes.itemDetailsScreen:
      //   return MaterialPageRoute(builder: (_) => ItemDetails());
      // case Routes.trackorder:
      //   return MaterialPageRoute(builder: (_) => const TrackOrder());
      // case Routes.exchangeOrRefund:
      //   return MaterialPageRoute(builder: (_) => const ExchangeOrRefund());
      case Routes.cancelSubscription:
        return MaterialPageRoute(builder: (_) => const CancelSubscription());
      case Routes.authScreen:
        return MaterialPageRoute(builder: (_) => const AuthScreen());
      default:
        return MaterialPageRoute(
          builder:
              (_) => Scaffold(
                body: Center(
                  child: Text('no route defined for ${settings.name} '),
                ),
              ),
        );
    }
  }
}
