import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/features/home/domain/feed_controller.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';

class HomeFAB extends ConsumerWidget {
  final User? firebaseUser;
  final int selectedIndex;

  const HomeFAB({
    super.key,
    required this.firebaseUser,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (firebaseUser == null || (selectedIndex != 0 && selectedIndex != 2)) {
      return const SizedBox.shrink();
    }

    return StreamBuilder(
      stream: ref.read(feedControllerProvider.notifier).getUserStream(firebaseUser!.uid),
      builder: (context, asyncSnapshot) {
        if (!asyncSnapshot.hasData) {
          return const SizedBox.shrink();
        }
        
        final userData = asyncSnapshot.data!.data() as Map<String, dynamic>?;
        if (userData == null) {
          return const SizedBox.shrink();
        }
        
        final currentUser = MyUser.fromDocument(userData);
        if (!currentUser.isSub) {
          return const SizedBox.shrink();
        }
        
        return FloatingActionButton(
          heroTag: selectedIndex == 0 ? "home_feed_fab" : "MY_feed_fab",
          shape: const CircleBorder(),
          backgroundColor: Colors.transparent,
          elevation: 0,
          highlightElevation: 0,
          onPressed: () {
            context.go(Routes.addPostScreen);
          },
          child: ClipOval(
            child: Image.asset(
              "assets/add_post_transparent.png",
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }
}
