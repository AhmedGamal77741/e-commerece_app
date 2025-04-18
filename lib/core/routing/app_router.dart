import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/features/home/home.dart';
import 'package:ecommerece_app/features/login/login.dart';
import 'package:ecommerece_app/features/review/ui/review_screen.dart';
import 'package:flutter/material.dart';

class AppRouter {
  Route generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.homeScreen:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
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
