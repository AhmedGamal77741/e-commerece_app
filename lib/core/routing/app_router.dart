import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/features/home/add_post.dart';
import 'package:ecommerece_app/features/home/comments.dart';
import 'package:ecommerece_app/features/home/notifications.dart';
import 'package:ecommerece_app/features/navBar/nav_bar.dart';
import 'package:ecommerece_app/features/login/login.dart';
import 'package:ecommerece_app/features/review/ui/review_screen.dart';
import 'package:ecommerece_app/features/review/ui/track_order.dart';
import 'package:flutter/material.dart';

class AppRouter {
  Route generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.navBar:
        return MaterialPageRoute(builder: (_) => const NavBar());
      case Routes.loginScreen:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case Routes.reviewScreen:
        return MaterialPageRoute(builder: (_) => const ReviewScreen());
      case Routes.commentsScreen:
        return MaterialPageRoute(builder: (_) => const Comments());
      case Routes.notificationsScreen:
        return MaterialPageRoute(builder: (_) => const Notifications());
      case Routes.addPostScreen:
        return MaterialPageRoute(builder: (_) => const AddPost());
      case Routes.trackorder:
        return MaterialPageRoute(builder: (_) => const TrackOrder());
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
