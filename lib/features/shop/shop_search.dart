import 'package:ecommerece_app/core/helpers/extensions.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
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
          icon: Icon(Icons.arrow_back_ios, color: ColorsManager.primary600),
          onPressed: () {
            context.pop();
          },
        ),
        title: SizedBox(
          height: 31.h,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search...',
              hintStyle: TextStyles.abeezee13px400wPblack,
              border: OutlineInputBorder(
                // Default border
                borderSide: BorderSide(color: ColorsManager.primary600),
                borderRadius: BorderRadius.zero, // Rectangular
              ),
              focusedBorder: OutlineInputBorder(
                // Border when selected
                borderSide: BorderSide(color: ColorsManager.primary600),
                borderRadius: BorderRadius.zero,
              ),
              enabledBorder: OutlineInputBorder(
                // Border when not selected
                borderSide: BorderSide(color: ColorsManager.primary600),
                borderRadius: BorderRadius.zero,
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: ImageIcon(AssetImage('assets/Frame 4.png')),
            iconSize: 30.sp,
            onPressed: () {},
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Best product",
              style: TextStyle(
                fontFamily: 'ABeeZee',
                fontSize: 26.sp,
                color: ColorsManager.primary600,
              ),
            ),
            Text(
              "Low price",
              style: TextStyle(
                fontFamily: 'ABeeZee',
                fontSize: 26.sp,
                color: ColorsManager.primary600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
