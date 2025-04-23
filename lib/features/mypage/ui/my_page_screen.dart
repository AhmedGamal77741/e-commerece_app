import 'package:ecommerece_app/core/widgets/tab_app_bar.dart';
import 'package:ecommerece_app/features/mypage/ui/my_page.dart';
import 'package:ecommerece_app/features/mypage/ui/my_story.dart';
import 'package:flutter/material.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: TabAppBar(
          imgUrl: 'mypage_icon.png',
          firstTab: '내 이야기',
          secondTab: '마이페이지',
        ),
        body: TabBarView(children: [MyStory(), MyPage()]),
      ),
    );
  }
}
