import 'package:ecommerece_app/core/widgets/tab_app_bar.dart';
import 'package:ecommerece_app/features/auth/Login/login_screen.dart';
import 'package:ecommerece_app/features/auth/signup/signup_screen.dart';
import 'package:flutter/material.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: TabAppBar(
          imgUrl: 'mypage_icon.png',
          firstTab: '로그인',
          secondTab: '회원가입',
        ),
        body: TabBarView(children: [LoginScreen(), SignupScreen()]),
      ),
    );
  }
}
