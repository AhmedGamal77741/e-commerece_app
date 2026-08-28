import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/features/cart/domain/checkout_form_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CheckoutReceiptOption extends ConsumerWidget {
  final VoidCallback onShowBottomSheet;

  const CheckoutReceiptOption({
    super.key,
    required this.onShowBottomSheet,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(checkoutFormControllerProvider).value;
    final selectedOption = state?.selectedOption ?? 1;
    final controller = ref.read(checkoutFormControllerProvider.notifier);

    String detailText = '현금영수증 발급 정보 입력';
    if (selectedOption == 1) {
      final phone = controller.phoneController.text.trim();
      detailText = phone.isNotEmpty ? '소득공제 ($phone)' : '소득공제 (휴대폰 번호)';
    } else {
      final bNum = controller.businessNumberController.text.trim();
      detailText = bNum.isNotEmpty ? '지출증빙 ($bNum)' : '지출증빙 (사업자등록번호)';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '현금영수증 발급 정보',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16.sp,
                  fontFamily: 'NotoSans',
                  fontWeight: FontWeight.w800,
                  height: 1.40.h,
                ),
              ),
              verticalSpace(5),
              Text(
                detailText,
                style: TextStyle(
                  fontSize: 15.sp,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onShowBottomSheet,
          icon: Icon(
            Icons.arrow_forward_ios,
            size: 30.r,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
