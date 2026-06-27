import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CheckoutPaymentSelector extends StatelessWidget {
  final List<Map<String, dynamic>> bankAccounts;
  final int selectedBankIndex;
  final VoidCallback onShowBottomSheet;

  const CheckoutPaymentSelector({
    super.key,
    required this.bankAccounts,
    required this.selectedBankIndex,
    required this.onShowBottomSheet,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '결제 계좌',
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
                bankAccounts.isEmpty
                    ? '등록된 계좌가 없습니다'
                    : (selectedBankIndex >= 0 &&
                            selectedBankIndex < bankAccounts.length)
                        ? '${bankAccounts[selectedBankIndex]['bankName']} '
                            '(${bankAccounts[selectedBankIndex]['bankNum']})'
                        : '계좌를 선택해주세요',
                style: TextStyle(
                  fontSize: 15.sp,
                  color: bankAccounts.isEmpty
                      ? Colors.red[300]
                      : Colors.grey[800],
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
