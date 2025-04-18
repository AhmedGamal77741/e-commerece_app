import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/features/navBar/navBar.dart';
import 'package:ecommerece_app/features/login/login.dart';
import 'package:ecommerece_app/features/review/ui/review_screen.dart';
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
