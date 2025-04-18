import 'package:ecommerece_app/core/widgets/tab_app_bar.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: TabAppBar(firstTab: 'Recommendations', secondTab: 'Friends'),
        body: TabBarView(
          children: [Center(child: Text('s')), Center(child: Text('data'))],
        ),
      ),
    );
  }
}
