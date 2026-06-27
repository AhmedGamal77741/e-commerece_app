import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EditBottomBar extends ConsumerWidget {
  final VoidCallback onDeselectAll;
  final VoidCallback onLeave;
  final bool hasSelection;

  const EditBottomBar({
    Key? key,
    required this.onDeselectAll,
    required this.onLeave,
    required this.hasSelection,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      color: hasSelection ? Colors.black : Colors.grey[100],
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onDeselectAll,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 18.h),
                  alignment: Alignment.center,
                  child: Text(
                    '선택해제',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                      color: hasSelection ? Colors.white : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              width: 1,
              height: 20.h,
              color: hasSelection ? Colors.white24 : Colors.grey[300],
            ),
            Expanded(
              child: InkWell(
                onTap: hasSelection ? onLeave : null,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 18.h),
                  alignment: Alignment.center,
                  child: Text(
                    '나가기',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: hasSelection ? Colors.white : Colors.grey[400],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
