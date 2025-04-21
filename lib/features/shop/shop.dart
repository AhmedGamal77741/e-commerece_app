import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/features/shop/dessert.dart';
import 'package:ecommerece_app/features/shop/fresh.dart';
import 'package:ecommerece_app/features/shop/household.dart';
import 'package:ecommerece_app/features/shop/instant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Shop extends StatefulWidget {
  const Shop({super.key});

  @override
  State<Shop> createState() => _ShopState();
}

class _ShopState extends State<Shop> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 130.h,
          backgroundColor: ColorsManager.white,
          title: TabBar(
            labelStyle: TextStyle(
              fontSize: 16.sp,
              decoration: TextDecoration.none,
              fontFamily: 'ABeeZee',
              fontStyle: FontStyle.normal,
              fontWeight: FontWeight.w400,
              letterSpacing: 0,
              color: ColorsManager.primaryblack,
            ),
            unselectedLabelColor: ColorsManager.primary600,
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorColor: ColorsManager.primaryblack,
            tabs: [
              Tab(text: "디저트"),
              Tab(text: "신선한"),
              Tab(text: "즉각적인"),
              Tab(text: "가정"),
            ],
          ),
        ),
        body: TabBarView(
          children: [Dessert(), Fresh(), Instant(), Household()],
        ),
      ),
    );
  }
}
