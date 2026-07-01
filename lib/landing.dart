import 'package:ecommerece_app/features/auth/auth_screen.dart';
import 'package:ecommerece_app/features/mypage/ui/my_page_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerece_app/features/auth/domain/auth_controller.dart';
import 'package:ecommerece_app/core/providers/firebase_providers.dart';

class LandingScreen extends ConsumerWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final authState = ref.watch(authStateProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return Stack(
            children: [
              const AuthScreen(),
              if (authState.value != null)
                Container(
                  color: const Color(0x80000000),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 20),
                        Text(
                          '계정 설정 마무리 중...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        } else {
          return MyPageScreen(currentUser: user);
        }
      },
      loading: () => const Scaffold(body: SizedBox.shrink()),
      error: (_, __) => const AuthScreen(),
    );
  }
}
