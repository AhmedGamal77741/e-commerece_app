import 'package:ecommerece_app/features/auth/auth_screen.dart';
import 'package:ecommerece_app/features/mypage/ui/my_page_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerece_app/features/auth/domain/auth_controller.dart';

class LandingScreen extends ConsumerWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return AuthScreen();
        } else {
          return MyPageScreen(currentUser: user);
        }
      },
      loading: () => const Scaffold(body: SizedBox.shrink()),
      error: (_, __) => AuthScreen(),
    );
  }
}
