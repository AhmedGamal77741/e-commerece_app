import 'package:ecommerece_app/core/helpers/loading_service.dart';
import 'package:ecommerece_app/features/mypage/ui/my_page.dart';
import 'package:flutter/material.dart';

import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';

class MyPageScreen extends StatefulWidget {
  final MyUser currentUser;
  const MyPageScreen({super.key, required this.currentUser});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(body: MyPage(currentUser: widget.currentUser)),
        ValueListenableBuilder<bool>(
          valueListenable: LoadingService().isLoading,
          builder: (context, isLoading, child) {
            return isLoading
                ? Container(
                  color: Colors.black54,
                  child: const SizedBox.shrink(),
                )
                : const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}
