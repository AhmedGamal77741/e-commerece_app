import 'package:ecommerece_app/core/helpers/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OrderComplete extends StatefulWidget {
  const OrderComplete({super.key});

  @override
  State<OrderComplete> createState() => _OrderCompleteState();
}

class _OrderCompleteState extends State<OrderComplete> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () {
            context.pop();
          },
          style: TextButton.styleFrom(
            backgroundColor: const Color(0xFF121212), // Background color
            foregroundColor: Colors.white, // Text color
            minimumSize: Size(220.w, 45.h), // Exact dimensions
            padding: EdgeInsets.zero, // Remove default padding
            shape: RoundedRectangleBorder(
              side: BorderSide(
                width: 1,
                color: const Color(0xFF121212),
              ), // Border
              borderRadius: BorderRadius.circular(8), // Corner radius
            ),
            elevation: 0, // Remove shadow
          ),
          child: Text(
            'Order Complete',
            style: TextStyle(
              color: const Color(0xFFF5F5F5),
              fontSize: 18.sp,
              fontFamily: 'ABeeZee',
              fontWeight: FontWeight.w400,
              height: 1.40.h,
            ),
          ),
        ),
      ),
    );
  }
}
