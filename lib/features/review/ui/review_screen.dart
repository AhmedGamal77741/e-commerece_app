import 'package:ecommerece_app/core/widgets/tab_app_bar.dart';
import 'package:flutter/material.dart';

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: TabAppBar(
          imgUrl: 'rev_icon.png',
          firstTab: 'Leave a Review',
          secondTab: 'Order history',
        ),
        body: TabBarView(
          children: [Center(child: Text('s')), Center(child: Text('data'))],
        ),
      ),
    );
  }
}
