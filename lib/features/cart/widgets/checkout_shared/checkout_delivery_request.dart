import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CheckoutDeliveryRequest extends StatelessWidget {
  final String selectedRequest;
  final String? manualRequest;
  final ValueChanged<String> onManualRequestChanged;
  final VoidCallback onShowSheet;

  const CheckoutDeliveryRequest({
    super.key,
    required this.selectedRequest,
    this.manualRequest,
    required this.onManualRequestChanged,
    required this.onShowSheet,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '배송 요청사항',
                style: TextStyles.abeezee16px400wPblack
                    .copyWith(fontWeight: FontWeight.w800),
              ),
              verticalSpace(5),
              Text(
                selectedRequest == '직접입력' &&
                        manualRequest != null &&
                        manualRequest!.isNotEmpty
                    ? manualRequest!
                    : selectedRequest,
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 16.sp,
                  fontFamily: 'NotoSans',
                  fontWeight: FontWeight.w400,
                ),
              ),
              if (selectedRequest == '직접입력') ...[
                SizedBox(height: 12.h),
                TextFormField(
                  initialValue: manualRequest,
                  onChanged: onManualRequestChanged,
                  decoration: InputDecoration(
                    labelText: '직접 입력',
                    hintText: '배송 요청을 입력하세요',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 14.h,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.arrow_forward_ios,
            size: 30.r,
            color: Colors.black,
          ),
          onPressed: onShowSheet,
        ),
      ],
    );
  }
}
