import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DateSeparator extends ConsumerWidget {
  final DateTime date;
  const DateSeparator({Key? key, required this.date}) : super(key: key);

  String _label() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return '오늘';
    if (d == today.subtract(const Duration(days: 1))) return '어제';
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.07),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _label(),
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
          ),
        ),
      ),
    );
  }
}
