import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ReqButton extends ConsumerWidget {
  final String txt;
  final VoidCallback func;
  final Color color;
  const ReqButton({
    super.key,
    required this.txt,
    required this.color,
    required this.func,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton(
      onPressed: func,
      style: TextButton.styleFrom(
        backgroundColor: color,
        fixedSize: Size(177.w, 83.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(txt, style: TextStyles.abeezee23px400wW),
    );
  }
}
