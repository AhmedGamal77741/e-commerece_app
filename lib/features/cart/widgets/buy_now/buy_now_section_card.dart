import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BuyNowSectionCard extends StatelessWidget {
  final Widget child;

  const BuyNowSectionCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(15.w, 15.h, 0, 15.h),
      decoration: ShapeDecoration(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1.5, color: Colors.black),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: child,
    );
  }
}
