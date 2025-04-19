import 'package:ecommerece_app/core/helpers/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ShopSearch extends StatefulWidget {
  const ShopSearch({super.key});

  @override
  State<ShopSearch> createState() => _ShopSearchState();
}

class _ShopSearchState extends State<ShopSearch> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 40.w,
        backgroundColor: Colors.white,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            context.pop();
          },
        ),
        title: TextField(
          decoration: InputDecoration(
            hintText: 'Search...',
            contentPadding: EdgeInsets.all(12),
            border: OutlineInputBorder(
              // Default border
              borderSide: BorderSide(color: Colors.grey),
              borderRadius: BorderRadius.zero, // Rectangular
            ),
            focusedBorder: OutlineInputBorder(
              // Border when selected
              borderSide: BorderSide(color: Colors.grey),
              borderRadius: BorderRadius.zero,
            ),
            enabledBorder: OutlineInputBorder(
              // Border when not selected
              borderSide: BorderSide(color: Colors.grey),
              borderRadius: BorderRadius.zero,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: ImageIcon(AssetImage('assets/Frame 4.png')),
            iconSize: 40.sp,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
